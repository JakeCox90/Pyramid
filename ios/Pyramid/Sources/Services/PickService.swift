import Foundation
import os
import Supabase

// MARK: - Error

enum PickServiceError: LocalizedError, Equatable {
    case noCurrentGameweek
    case fetchFailed(String)
    case submitFailed(String)

    var errorDescription: String? {
        switch self {
        case .noCurrentGameweek:
            return "No active gameweek found."
        case .fetchFailed(let message):
            return message
        case .submitFailed(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol PickServiceProtocol: Sendable {
    func fetchCurrentGameweek() async throws -> Gameweek
    func fetchFixtures(for gameweekId: Int) async throws -> [Fixture]
    func fetchMyPick(leagueId: String, gameweekId: Int) async throws -> Pick?
    func fetchUsedTeamIds(leagueId: String) async throws -> Set<Int>
    func submitPick(leagueId: String, fixtureId: Int, teamId: Int, teamName: String) async throws -> SubmitPickResponse
    func fetchMyPickHistory(leagueId: String) async throws -> [Pick]
}

// MARK: - Implementation

final class PickService: PickServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchCurrentGameweek() async throws -> Gameweek {
        do {
            let gameweeks: [Gameweek] = try await client
                .from("gameweeks")
                .select("id, season, round_number, name, deadline_at, is_current, is_finished")
                .eq("is_current", value: true)
                .limit(1)
                .execute()
                .value
            guard let gameweek = gameweeks.first else {
                throw PickServiceError.noCurrentGameweek
            }
            return gameweek
        } catch let error as PickServiceError {
            throw error
        } catch {
            throw PickServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchFixtures(for gameweekId: Int) async throws -> [Fixture] {
        do {
            let fixtures: [Fixture] = try await client
                .from("fixtures")
                .select("""
                    id, gameweek_id,
                    home_team_id, home_team_name, home_team_short, home_team_logo,
                    away_team_id, away_team_name, away_team_short, away_team_logo,
                    kickoff_at, status, home_score, away_score
                """)
                .eq("gameweek_id", value: gameweekId)
                .order("kickoff_at", ascending: true)
                .execute()
                .value
            return fixtures
        } catch {
            throw PickServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchUsedTeamIds(leagueId: String) async throws -> Set<Int> {
        struct UsedTeamRow: Decodable {
            let teamId: Int
            enum CodingKeys: String, CodingKey {
                case teamId = "team_id"
            }
        }
        do {
            let rows: [UsedTeamRow] = try await client
                .from("used_teams")
                .select("team_id")
                .eq("league_id", value: leagueId)
                .execute()
                .value
            return Set(rows.map(\.teamId))
        } catch {
            throw PickServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchMyPick(leagueId: String, gameweekId: Int) async throws -> Pick? {
        do {
            let picks: [Pick] = try await client
                .from("picks")
                .select("""
                    id, league_id, user_id, gameweek_id, fixture_id,
                    team_id, team_name, is_locked, result, submitted_at
                """)
                .eq("league_id", value: leagueId)
                .eq("gameweek_id", value: gameweekId)
                .limit(1)
                .execute()
                .value
            return picks.first
        } catch {
            throw PickServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchMyPickHistory(leagueId: String) async throws -> [Pick] {
        do {
            let picks: [Pick] = try await client
                .from("picks")
                .select("""
                    id, league_id, user_id, gameweek_id, fixture_id,
                    team_id, team_name, is_locked, result, submitted_at
                """)
                .eq("league_id", value: leagueId)
                .order("gameweek_id", ascending: true)
                .execute()
                .value
            return picks
        } catch {
            throw PickServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func submitPick(
        leagueId: String,
        fixtureId: Int,
        teamId: Int,
        teamName: String
    ) async throws -> SubmitPickResponse {
        struct SubmitPickBody: Encodable {
            let leagueId: String
            let fixtureId: Int
            let teamId: Int
            let teamName: String
            enum CodingKeys: String, CodingKey {
                case leagueId = "league_id"
                case fixtureId = "fixture_id"
                case teamId = "team_id"
                case teamName = "team_name"
            }
        }
        do {
            Log.picks.info("Submitting pick: team=\(teamName) fixture=\(fixtureId)")
            let response: SubmitPickResponse = try await client.functions.invoke(
                "submit-pick",
                options: FunctionInvokeOptions(body: SubmitPickBody(
                    leagueId: leagueId,
                    fixtureId: fixtureId,
                    teamId: teamId,
                    teamName: teamName
                ))
            )
            Log.picks.info("Pick submitted successfully: \(response.pickId)")
            return response
        } catch {
            Log.picks.error("Pick submission failed: \(error.localizedDescription)")
            throw PickServiceError.submitFailed(error.localizedDescription)
        }
    }
}
