import Foundation

struct Gameweek: Identifiable, Codable, Sendable, Equatable {
    let id: Int
    let season: Int
    let roundNumber: Int
    let name: String
    let deadlineAt: Date?
    let isCurrent: Bool
    let isFinished: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case season
        case roundNumber = "round_number"
        case name
        case deadlineAt = "deadline_at"
        case isCurrent = "is_current"
        case isFinished = "is_finished"
    }
}
