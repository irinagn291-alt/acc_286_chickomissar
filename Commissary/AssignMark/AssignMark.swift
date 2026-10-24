import Foundation

/// Commit that seats a Stock tin on a cook-day ticket and folds it to Assigned.
struct AssignMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var sequence: Int
    var tinID: UUID
    var cookDaykey: Int
    var recordedAt: Date
}
