import Foundation

/// Bundled identity shelf. Used when Open Food Facts is unreachable. Names only, no meal slots.
enum LocalShelfCatalog {
    static let products: [ShelfIdentity] = [
        ShelfIdentity(barcode: "5000159461122", title: "Oat tin", brand: "Millhouse"),
        ShelfIdentity(barcode: "3017620422003", title: "Tomato tin", brand: "Grove"),
        ShelfIdentity(barcode: "8000500310427", title: "Chickpea tin", brand: "Harbour"),
        ShelfIdentity(barcode: "737628064502", title: "Rice tin", brand: "Drydock"),
    ]

    static func match(barcode: String) -> ShelfIdentity? {
        let wanted = BarcodePayload.candidates(in: barcode)
        return products.first { product in
            let known = BarcodePayload.candidates(in: product.barcode)
            return !Set(wanted).isDisjoint(with: known) || product.barcode == barcode
        }
    }

    static func search(terms: String) -> [ShelfIdentity] {
        let needle = terms.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty { return [] }
        return products.filter {
            $0.title.lowercased().contains(needle) || $0.brand.lowercased().contains(needle)
        }
    }
}

/// Domain identity mapped from an Open Food Facts DTO or the local shelf. Not a tin.
struct ShelfIdentity: Codable, Sendable, Equatable, Identifiable {
    var barcode: String
    var title: String
    var brand: String

    var id: String { barcode }
}
