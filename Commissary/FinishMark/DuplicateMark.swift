import Foundation

/// Refusal record. A second Assign while the tin is Assigned appends this and changes nothing else.
struct DuplicateMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var sequence: Int
    var tinID: UUID
    var cookDaykey: Int
    var recordedAt: Date
}
