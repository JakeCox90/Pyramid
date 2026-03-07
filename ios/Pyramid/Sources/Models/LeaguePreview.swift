import Foundation

struct LeaguePreview: Codable, Sendable {
    let leagueId: String
    let name: String
    let memberCount: Int
    let status: String
    let season: Int

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case name
        case memberCount = "member_count"
        case status
        case season
    }
}

struct JoinLeagueResponse: Codable, Sendable {
    let leagueId: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case name
    }
}
