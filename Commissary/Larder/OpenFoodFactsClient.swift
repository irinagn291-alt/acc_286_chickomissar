import Foundation

/// One client for Open Food Facts search and product lookup. DTOs stay in this file.
/// Domain code receives ShelfIdentity. A missing energy value is normal and is not an error.
actor OpenFoodFactsClient {
    static let userAgent = "Chickomissar/1.0 (iOS; +https://commissary-larder.pro)"
    static let host = "https://world.openfoodfacts.org"

    private let session: URLSession
    private let cacheURL: URL
    private let disk: LarderDisk
    private let debounce: Duration
    private var generation = 0
    private var cache: [String: ShelfIdentity] = [:]
    private var cacheWriteFailed = false

    init(cacheDirectory: URL, debounce: Duration = .milliseconds(300), session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 15
            configuration.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
            self.session = URLSession(configuration: configuration)
        }
        self.cacheURL = cacheDirectory.appendingPathComponent("off-identity.json")
        self.disk = LarderDisk()
        self.debounce = debounce
    }

    func loadCache() async {
        guard let data = await disk.read(from: cacheURL) else { return }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        if let stored = try? decoder.decode([String: ShelfIdentity].self, from: data) {
            cache = stored
        }
        try? await disk.excludeFromBackup(cacheURL)
    }

    /// Empty terms never hit the network. A newer call cancels the previous search.
    func search(terms: String) async throws -> [ShelfIdentity] {
        let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }
        generation &+= 1
        let token = generation
        do {
            try await Task.sleep(for: debounce)
        } catch is CancellationError {
            throw CancellationError()
        }
        guard token == generation else { throw CancellationError() }
        do {
            let data = try await fetch(searchRequest(terms: trimmed))
            guard token == generation else { throw CancellationError() }
            let hits = try ShelfDecoder.identities(fromSearch: data)
            for hit in hits {
                cache[hit.barcode] = hit
            }
            await storeCache()
            return hits
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ShelfLookupError {
            let local = LocalShelfCatalog.search(terms: trimmed)
            if local.isEmpty { throw error }
            return local
        } catch {
            let local = LocalShelfCatalog.search(terms: trimmed)
            if local.isEmpty { throw ShelfLookupError.transport }
            return local
        }
    }

    func product(barcode: String) async throws -> ShelfIdentity {
        let candidates = BarcodePayload.candidates(in: barcode)
        let codes = candidates.isEmpty ? [barcode] : candidates
        for code in codes {
            if let cached = cache[code] { return cached }
            if let local = LocalShelfCatalog.match(barcode: code) {
                cache[code] = local
                return local
            }
        }
        var lastError: ShelfLookupError = .notFound
        for code in codes {
            do {
                let data = try await fetch(productRequest(barcode: code))
                let identity = try ShelfDecoder.identity(fromProduct: data, fallbackCode: code)
                cache[identity.barcode] = identity
                await storeCache()
                return identity
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as ShelfLookupError {
                lastError = error
                if error == .notFound { continue }
            } catch {
                lastError = .transport
            }
        }
        throw lastError
    }

    private func storeCache() async {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            let data = try encoder.encode(cache)
            try await disk.persist(data, to: cacheURL)
            try await disk.excludeFromBackup(cacheURL)
            cacheWriteFailed = false
        } catch {
            cacheWriteFailed = true
        }
    }

    private func searchRequest(terms: String) throws -> URLRequest {
        guard var components = URLComponents(string: "\(Self.host)/cgi/search.pl") else {
            throw ShelfLookupError.malformed
        }
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: terms),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: "code,product_name,brands"),
        ]
        guard let url = components.url else { throw ShelfLookupError.malformed }
        return prepared(url)
    }

    private func productRequest(barcode: String) throws -> URLRequest {
        let encoded = barcode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? barcode
        guard let url = URL(string: "\(Self.host)/api/v2/product/\(encoded).json") else {
            throw ShelfLookupError.malformed
        }
        return prepared(url)
    }

    private func prepared(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try validate(try await once(request))
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ShelfLookupError {
            throw error
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where Self.isTransient(error.code) {
            do {
                return try validate(try await once(request))
            } catch is CancellationError {
                throw CancellationError()
            } catch let retry as ShelfLookupError {
                throw retry
            } catch let retry as URLError where retry.code == .cancelled {
                throw CancellationError()
            } catch {
                throw ShelfLookupError.transport
            }
        } catch {
            throw ShelfLookupError.transport
        }
    }

    private func once(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ShelfLookupError.transport
        }
        return (data, http)
    }

    private func validate(_ pair: (Data, HTTPURLResponse)) throws -> Data {
        if pair.1.statusCode == 404 { throw ShelfLookupError.notFound }
        guard (200...299).contains(pair.1.statusCode) else { throw ShelfLookupError.transport }
        return pair.0
    }

    private static func isTransient(_ code: URLError.Code) -> Bool {
        switch code {
        case .timedOut, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
             .dnsLookupFailed, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }
}

enum ShelfLookupError: Error, Equatable {
    case notFound
    case transport
    case malformed
}

enum ShelfDecoder {
    static func identity(fromProduct data: Data, fallbackCode: String) throws -> ShelfIdentity {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let envelope: ProductEnvelope
        do {
            envelope = try decoder.decode(ProductEnvelope.self, from: data)
        } catch {
            throw ShelfLookupError.malformed
        }
        if envelope.status == 0 { throw ShelfLookupError.notFound }
        guard let product = envelope.product else { throw ShelfLookupError.notFound }
        let title = product.product_name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if title.isEmpty { throw ShelfLookupError.notFound }
        let code = product.code?.isEmpty == false ? (product.code ?? fallbackCode) : fallbackCode
        return ShelfIdentity(barcode: code, title: title, brand: product.brands ?? "")
    }

    static func identities(fromSearch data: Data) throws -> [ShelfIdentity] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let envelope: SearchEnvelope
        do {
            envelope = try decoder.decode(SearchEnvelope.self, from: data)
        } catch {
            throw ShelfLookupError.malformed
        }
        return (envelope.products ?? []).compactMap { product in
            guard let code = product.code, !code.isEmpty,
                  let name = product.product_name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else {
                return nil
            }
            return ShelfIdentity(barcode: code, title: name, brand: product.brands ?? "")
        }
    }

    /// Accepts number or numeric string. kcal comes from energy-kcal_100g, else energy_kcal_100g, else kJ / 4.184.
    static func nutrimentKcal(from data: Data) -> Double? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        guard let envelope = try? decoder.decode(ProductEnvelope.self, from: data),
              let nutriments = envelope.product?.nutriments else {
            return nil
        }
        if let kcal = nutriments.energyKcal100g?.value { return kcal }
        if let kcal = nutriments.energyKcal100gAlt?.value { return kcal }
        if let kilojoules = nutriments.energyKj100g?.value { return kilojoules / 4.184 }
        return nil
    }
}

private struct ProductEnvelope: Decodable {
    var status: Int?
    var product: ProductDTO?
}

private struct SearchEnvelope: Decodable {
    var products: [ProductDTO]?
}

private struct ProductDTO: Decodable {
    var product_name: String?
    var brands: String?
    var code: String?
    var nutriments: NutrimentDTO?
}

private struct NutrimentDTO: Decodable {
    var energyKcal100g: FlexibleNumber?
    var energyKcal100gAlt: FlexibleNumber?
    var energyKj100g: FlexibleNumber?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energyKcal100gAlt = "energy_kcal_100g"
        case energyKj100g = "energy-kj_100g"
    }
}

private struct FlexibleNumber: Decodable {
    var value: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}
