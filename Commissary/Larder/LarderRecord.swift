import Foundation

/// Single root document for the larder. Marks are the log. Phase is a fold over them.
/// schemaVersion starts at 1. The decoder rejects any other version so a future file can migrate.
struct LarderRecord: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var tins: [Tin]
    var archivedTins: [Tin]
    var assignMarks: [AssignMark]
    var finishMarks: [FinishMark]
    var wasteMarks: [WasteMark]
    var earlyMarks: [EarlyMark]
    var duplicateMarks: [DuplicateMark]
    var onboardingComplete: Bool
    var cookHorizonDays: Int
    var nextSequence: Int

    static let currentSchema = 1

    static var empty: LarderRecord {
        LarderRecord(
            schemaVersion: currentSchema,
            tins: [],
            archivedTins: [],
            assignMarks: [],
            finishMarks: [],
            wasteMarks: [],
            earlyMarks: [],
            duplicateMarks: [],
            onboardingComplete: false,
            cookHorizonDays: 7,
            nextSequence: 1
        )
    }

    static func decode(_ data: Data) -> Result<LarderRecord, Error> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            let record = try decoder.decode(LarderRecord.self, from: data)
            guard record.schemaVersion == currentSchema else {
                return .failure(LarderDecodeError.unsupportedSchema(record.schemaVersion))
            }
            return .success(record)
        } catch {
            return .failure(error)
        }
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    func tin(id: UUID) -> Tin? {
        tins.first { $0.id == id } ?? archivedTins.first { $0.id == id }
    }

    mutating func takeSequence() -> Int {
        let value = nextSequence
        nextSequence += 1
        return value
    }
}

enum LarderDecodeError: Error, Equatable {
    case unsupportedSchema(Int)
}

enum LarderKeys {
    static let record = "cms.larder.v1"
    static let demo = "cms.demo.v1"
}
