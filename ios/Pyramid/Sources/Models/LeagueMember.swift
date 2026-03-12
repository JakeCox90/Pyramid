import Foundation

struct LeagueMember: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let userId: String
    let status: MemberStatus
    let joinedAt: Date
    let eliminatedAt: Date?
    let eliminatedInGameweekId: Int?
    let profiles: MemberProfile

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case joinedAt = "joined_at"
        case eliminatedAt = "eliminated_at"
        case eliminatedInGameweekId = "eliminated_in_gameweek_id"
        case profiles
    }

    enum MemberStatus: String, Codable, Sendable {
        case active
        case eliminated
        case winner

        var sortOrder: Int {
            switch self {
            case .winner:     return 0
            case .active:     return 1
            case .eliminated: return 2
            }
        }
    }

    struct MemberProfile: Codable, Sendable, Equatable {
        let username: String
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case username
            case displayName = "display_name"
        }

        var displayLabel: String {
            displayName ?? username
        }
    }
}

struct MemberPick: Codable, Sendable, Equatable {
    let userId: String
    let teamName: String
    let result: PickResult
    let isLocked: Bool
    let gameweekId: Int
    let fixtureId: Int
    let teamId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case teamName = "team_name"
        case result
        case isLocked = "is_locked"
        case gameweekId = "gameweek_id"
        case fixtureId = "fixture_id"
        case teamId = "team_id"
    }
}
