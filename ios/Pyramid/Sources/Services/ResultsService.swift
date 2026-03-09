import Foundation
import Supabase

// MARK: - Error

enum ResultsServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

// MARK: - Response Types

struct RoundPickRow: Codable, Sendable, Equatable, Identifiable {
    var id: String { "\(userId)-\(gameweekId)" }

    let userId: String
    let teamName: String
    let result: PickResult
    let gameweekId: Int
    let fixtureId: Int
    let profiles: LeagueMember.MemberProfile

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case teamName = "team_name"
        case result
        case gameweekId = "gameweek_id"
        case fixtureId = "fixture_id"
        case profiles
    }
}

// MARK: - Protocol

protocol ResultsServiceProtocol: Sendable {
    func fetchFinishedGameweeks(season: Int) async throws -> [Gameweek]
    func fetchSettledPicks(leagueId: String) async throws -> [RoundPickRow]
    func fetchFixtures(gameweekIds: [Int]) async throws -> [Fixture]
}

// MARK: - Implementation

final class ResultsService: ResultsServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchFinishedGameweeks(season: Int) async throws -> [Gameweek] {
        do {
            let gameweeks: [Gameweek] = try await client
                .from("gameweeks")
                .select("""
                    id, season, round_number, name,
                    deadline_at, is_current, is_finished
                """)
                .eq("season", value: season)
                .eq("is_finished", value: true)
                .order("round_number", ascending: false)
                .execute()
                .value
            return gameweeks
        } catch {
            throw ResultsServiceError.fetchFailed(
                error.localizedDescription
            )
        }
    }

    func fetchSettledPicks(leagueId: String) async throws -> [RoundPickRow] {
        do {
            let picks: [RoundPickRow] = try await client
                .from("picks")
                .select("""
                    user_id, team_name, result,
                    gameweek_id, fixture_id,
                    profiles(username, display_name)
                """)
                .eq("league_id", value: leagueId)
                .eq("is_locked", value: true)
                .neq("result", value: "pending")
                .order("gameweek_id", ascending: false)
                .execute()
                .value
            return picks
        } catch {
            throw ResultsServiceError.fetchFailed(
                error.localizedDescription
            )
        }
    }

    func fetchFixtures(gameweekIds: [Int]) async throws -> [Fixture] {
        guard !gameweekIds.isEmpty else { return [] }
        do {
            let fixtures: [Fixture] = try await client
                .from("fixtures")
                .select("""
                    id, gameweek_id,
                    home_team_id, home_team_name, home_team_short,
                    away_team_id, away_team_name, away_team_short,
                    kickoff_at, status, home_score, away_score
                """)
                .in("gameweek_id", values: gameweekIds)
                .eq("status", value: "FT")
                .order("kickoff_at", ascending: true)
                .execute()
                .value
            return fixtures
        } catch {
            throw ResultsServiceError.fetchFailed(
                error.localizedDescription
            )
        }
    }
}
