import Foundation
import Supabase

// MARK: - Gameweeks & Player Counts

extension HomeService {
    /// Fetches all gameweeks for the given season, ordered
    /// by round number descending (newest first).
    func fetchAllGameweeks(
        season: Int
    ) async throws -> [Gameweek] {
        let rows: [Gameweek] = try await client
            .from("gameweeks")
            .select(
                """
                id, season, round_number, name, \
                deadline_at, is_current, is_finished
                """
            )
            .eq("season", value: season)
            .order("round_number", ascending: false)
            .execute()
            .value

        return rows
    }

    /// Fetches active and total player counts for a league.
    func fetchPlayerCounts(
        leagueId: String
    ) async throws -> (active: Int, total: Int) {
        let rows: [PlayerCountRow] = try await client
            .from("league_members")
            .select("status")
            .eq("league_id", value: leagueId)
            .execute()
            .value

        let total = rows.count
        let active = rows.filter { $0.status == .active }.count
        return (active: active, total: total)
    }

    /// Fetches settled picks for a user in a specific gameweek
    /// across given leagues, paired with fixture data.
    func fetchPicksForGameweek(
        userId: String,
        gameweek: Gameweek,
        leagueIds: [String],
        leagueNames: [String: String]
    ) async throws -> [LeagueResult] {
        guard !leagueIds.isEmpty else { return [] }

        let picks: [Pick] = try await client
            .from("picks")
            .select(
                """
                id, league_id, user_id, gameweek_id, \
                fixture_id, team_id, team_name, \
                is_locked, result, submitted_at
                """
            )
            .eq("user_id", value: userId)
            .eq("gameweek_id", value: gameweek.id)
            .in("league_id", values: leagueIds)
            .execute()
            .value

        guard !picks.isEmpty else { return [] }

        let fixtureIds = Array(Set(picks.map(\.fixtureId)))
        let fixtures: [Fixture] = try await client
            .from("fixtures")
            .select(
                """
                id, gameweek_id, home_team_id, \
                home_team_name, home_team_short, \
                home_team_logo, away_team_id, \
                away_team_name, away_team_short, \
                away_team_logo, kickoff_at, status, \
                home_score, away_score, venue
                """
            )
            .in("id", values: fixtureIds)
            .execute()
            .value

        let fixtureMap = Dictionary(
            uniqueKeysWithValues: fixtures.map {
                ($0.id, $0)
            }
        )

        return picks.compactMap {
            Self.buildResult(
                pick: $0,
                gameweek: gameweek,
                fixtureMap: fixtureMap,
                leagueNames: leagueNames
            )
        }
    }

    private static func buildResult(
        pick: Pick,
        gameweek: Gameweek,
        fixtureMap: [Int: Fixture],
        leagueNames: [String: String]
    ) -> LeagueResult? {
        guard let fixture = fixtureMap[pick.fixtureId],
              let name = leagueNames[pick.leagueId]
        else { return nil }
        return LeagueResult(
            leagueId: pick.leagueId,
            leagueName: name,
            gameweekName: gameweek.name,
            teamName: pick.teamName,
            teamId: pick.teamId,
            result: pick.result,
            homeTeamId: fixture.homeTeamId,
            homeTeamName: fixture.homeTeamName,
            homeTeamShort: fixture.homeTeamShort,
            homeTeamLogo: fixture.homeTeamLogo,
            awayTeamId: fixture.awayTeamId,
            awayTeamName: fixture.awayTeamName,
            awayTeamShort: fixture.awayTeamShort,
            awayTeamLogo: fixture.awayTeamLogo,
            homeScore: fixture.homeScore ?? 0,
            awayScore: fixture.awayScore ?? 0
        )
    }
}

// MARK: - Private Types

private struct PlayerCountRow: Decodable {
    let status: LeagueMember.MemberStatus
}
