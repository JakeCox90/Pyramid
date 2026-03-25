import Foundation
import Supabase

// MARK: - Protocol

protocol GameweekStoryServiceProtocol: Sendable {
    func fetchStory(leagueId: String, gameweekId: Int) async throws -> GameweekStory?
    func fetchUpsetFixture(fixtureId: Int) async throws -> Fixture?
    func fetchWildcardPick(pickId: String) async throws -> Pick?
    func fetchStoryViewed(leagueId: String, gameweekId: Int) async throws -> Bool
    func markStoryViewed(leagueId: String, gameweekId: Int) async throws
}

// MARK: - Implementation

final class GameweekStoryService: GameweekStoryServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchStory(leagueId: String, gameweekId: Int) async throws -> GameweekStory? {
        let stories: [GameweekStory] = try await client
            .from("gameweek_stories")
            .select("*")
            .eq("league_id", value: leagueId)
            .eq("gameweek_id", value: gameweekId)
            .limit(1)
            .execute()
            .value
        return stories.first
    }

    func fetchUpsetFixture(fixtureId: Int) async throws -> Fixture? {
        let fixtures: [Fixture] = try await client
            .from("fixtures")
            .select("*")
            .eq("id", value: fixtureId)
            .limit(1)
            .execute()
            .value
        return fixtures.first
    }

    func fetchWildcardPick(pickId: String) async throws -> Pick? {
        let picks: [Pick] = try await client
            .from("picks")
            .select("*")
            .eq("id", value: pickId)
            .limit(1)
            .execute()
            .value
        return picks.first
    }

    func fetchStoryViewed(leagueId: String, gameweekId: Int) async throws -> Bool {
        let userId = try await client.auth.session.user.id.uuidString
        let views: [StoryViewRow] = try await client
            .from("story_views")
            .select("id")
            .eq("user_id", value: userId)
            .eq("league_id", value: leagueId)
            .eq("gameweek_id", value: gameweekId)
            .limit(1)
            .execute()
            .value
        return !views.isEmpty
    }

    func markStoryViewed(leagueId: String, gameweekId: Int) async throws {
        let userId = try await client.auth.session.user.id.uuidString
        try await client
            .from("story_views")
            .upsert(
                StoryViewInsert(userId: userId, leagueId: leagueId, gameweekId: gameweekId),
                onConflict: "user_id,league_id,gameweek_id"
            )
            .execute()
    }
}

// MARK: - Private helpers

private struct StoryViewRow: Decodable {
    let id: String
}

private struct StoryViewInsert: Encodable {
    let userId: String
    let leagueId: String
    let gameweekId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case leagueId = "league_id"
        case gameweekId = "gameweek_id"
    }
}
