import Foundation

struct Pick: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let leagueId: String
    let userId: String
    let gameweekId: Int
    let fixtureId: Int
    let teamId: Int
    let teamName: String
    let isLocked: Bool
    let result: PickResult
    let submittedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case userId = "user_id"
        case gameweekId = "gameweek_id"
        case fixtureId = "fixture_id"
        case teamId = "team_id"
        case teamName = "team_name"
        case isLocked = "is_locked"
        case result
        case submittedAt = "submitted_at"
    }
}

enum PickResult: String, Codable, Sendable {
    case pending
    case survived
    case eliminated
    case void
}

struct SubmitPickResponse: Codable, Sendable {
    let pickId: String
    let teamName: String
    let fixtureId: Int
    let isLocked: Bool

    enum CodingKeys: String, CodingKey {
        case pickId = "pick_id"
        case teamName = "team_name"
        case fixtureId = "fixture_id"
        case isLocked = "is_locked"
    }
}
