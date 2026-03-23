import Foundation

struct GameweekStory: Codable, Sendable, Equatable {
    let id: String
    let leagueId: String
    let gameweekId: Int
    let headline: String?
    let body: String?
    let wildcardPickId: String?
    let upsetFixtureId: Int?
    let isMassElimination: Bool
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case gameweekId = "gameweek_id"
        case headline
        case body
        case wildcardPickId = "wildcard_pick_id"
        case upsetFixtureId = "upset_fixture_id"
        case isMassElimination = "is_mass_elimination"
        case generatedAt = "generated_at"
    }
}
