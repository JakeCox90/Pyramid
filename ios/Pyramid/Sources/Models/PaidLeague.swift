import Foundation

// MARK: - PaidLeagueStatus

enum PaidLeagueStatus: String, Codable, Sendable {
    case waiting
    case active
    case complete
}

// MARK: - JoinPaidLeagueResponse

struct JoinPaidLeagueResponse: Codable, Sendable {
    let leagueId: String
    let pseudonym: String
    let status: PaidLeagueStatus
    let playerCount: Int

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case pseudonym
        case status
        case playerCount = "player_count"
    }
}
