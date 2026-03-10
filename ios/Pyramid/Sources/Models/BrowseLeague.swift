import Foundation

/// A free league available for the user to join, with member count.
struct BrowseLeague: Identifiable, Sendable {
    let id: String
    let name: String
    let joinCode: String
    let status: League.LeagueStatus
    let season: Int
    let createdAt: Date
    let memberCount: Int
}

/// Raw row from Supabase query with nested aggregate count.
struct BrowseLeagueRow: Decodable {
    let id: String
    let name: String
    let joinCode: String
    let status: League.LeagueStatus
    let season: Int
    let createdAt: Date
    let leagueMembers: [MemberCount]

    struct MemberCount: Decodable {
        let count: Int
    }

    enum CodingKeys: String, CodingKey {
        case id, name, status, season
        case joinCode = "join_code"
        case createdAt = "created_at"
        case leagueMembers = "league_members"
    }

    func toBrowseLeague() -> BrowseLeague {
        BrowseLeague(
            id: id,
            name: name,
            joinCode: joinCode,
            status: status,
            season: season,
            createdAt: createdAt,
            memberCount: leagueMembers.first?.count ?? 0
        )
    }
}
