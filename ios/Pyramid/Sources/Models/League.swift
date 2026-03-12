import Foundation

struct League: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let joinCode: String
    let type: LeagueType
    let status: LeagueStatus
    let season: Int
    let createdAt: Date
    var memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case joinCode = "join_code"
        case type
        case status
        case season
        case createdAt = "created_at"
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
