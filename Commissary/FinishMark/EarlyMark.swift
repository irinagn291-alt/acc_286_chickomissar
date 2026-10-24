import Foundation

/// Refusal record. Finish on Stock appends this and leaves the tin in Stock.
struct EarlyMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var sequence: Int
    var tinID: UUID
    var recordedAt: Date
}
