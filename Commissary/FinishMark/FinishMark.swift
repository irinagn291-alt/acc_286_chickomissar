import Foundation

/// Commit that folds an Assigned tin to Cleared when it is actually used.
struct FinishMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var sequence: Int
    var tinID: UUID
    var recordedAt: Date
}
