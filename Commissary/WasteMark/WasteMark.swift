import Foundation

/// Commit that clears a tin without a cook-day claim.
struct WasteMark: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var sequence: Int
    var tinID: UUID
    var recordedAt: Date
}
