import Foundation

struct League: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let joinCode: String
    let type: LeagueType
    let status: LeagueStatus
    let season: Int
    let createdAt: Date
    let createdBy: String?
    let colorPalette: String
    let emoji: String
    let description: String?
    var memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case joinCode = "join_code"
        case type
        case status
        case season
        case createdAt = "created_at"
        case createdBy = "created_by"
        case colorPalette = "color_palette"
        case emoji
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        joinCode = try container.decode(String.self, forKey: .joinCode)
        type = try container.decode(LeagueType.self, forKey: .type)
        status = try container.decode(LeagueStatus.self, forKey: .status)
        season = try container.decode(Int.self, forKey: .season)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        colorPalette = try container.decodeIfPresent(
            String.self,
            forKey: .colorPalette
        ) ?? "primary"
        emoji = try container.decodeIfPresent(
            String.self,
            forKey: .emoji
        ) ?? "⚽"
        description = try container.decodeIfPresent(
            String.self,
            forKey: .description
        )
    }

    init(
        id: String,
        name: String,
        joinCode: String,
        type: LeagueType,
        status: LeagueStatus,
        season: Int,
        createdAt: Date,
        createdBy: String? = nil,
        colorPalette: String = "primary",
        emoji: String = "⚽",
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.joinCode = joinCode
        self.type = type
        self.status = status
        self.season = season
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.colorPalette = colorPalette
        self.emoji = emoji
        self.description = description
    }

    enum LeagueType: String, Codable, Sendable {
        case free
        case paid
    }

    enum LeagueStatus: String, Codable, Sendable {
        case pending
        case active
        case completed
        case cancelled
    }
}

extension League.LeagueStatus {
    var displayName: String {
        switch self {
        case .pending:   return "Waiting for players"
        case .active:    return "In progress"
        case .completed: return "Finished"
        case .cancelled: return "Cancelled"
        }
    }
}

struct CreateLeagueResponse: Codable, Sendable {
    let leagueId: String
    let joinCode: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case joinCode = "join_code"
        case name
    }
}
