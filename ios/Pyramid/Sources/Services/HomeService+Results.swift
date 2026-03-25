import Foundation
import Supabase

// MARK: - Last Gameweek Results

extension HomeService {
    func fetchLastFinishedGameweek() async throws -> Gameweek? {
        let rows: [Gameweek] = try await client
            .from("gameweeks")
            .select(
                """
                id, season, round_number, name, \
                deadline_at, is_current, is_finished
                """
            )
            .eq("is_finished", value: true)
            .order("round_number", ascending: false)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    func fetchLastGwResults(
        userId: String,
        gameweek: Gameweek,
        leagueIds: [String],
        leagueNames: [String: String]
    ) async throws -> [LeagueResult] {
        let picks: [Pick] = try await client
            .from("picks")
            .select(
                """
                id, league_id, user_id, gameweek_id, fixture_id, \
                team_id, team_name, is_locked, result, submitted_at
                """
            )
            .eq("user_id", value: userId)
            .eq("gameweek_id", value: gameweek.id)
            .in("league_id", values: leagueIds)
            .neq("result", value: "pending")
            .execute()
            .value

        guard !picks.isEmpty else { return [] }

        let fixtureMap = try await fetchFixtureMap(
            for: picks.map(\.fixtureId)
        )

        return picks.compactMap { pick in
            makeLeagueResult(
                pick: pick,
                gameweek: gameweek,
                fixtureMap: fixtureMap,
                leagueNames: leagueNames
            )
        }
    }

    private func fetchFixtureMap(
        for fixtureIds: [Int]
    ) async throws -> [Int: Fixture] {
        let fixtures: [Fixture] = try await client
            .from("fixtures")
            .select(
                """
                id, gameweek_id, home_team_id, home_team_name, \
                home_team_short, home_team_logo, away_team_id, \
                away_team_name, away_team_short, away_team_logo, \
                kickoff_at, status, home_score, away_score, venue
                """
            )
            .in("id", values: fixtureIds)
            .execute()
            .value

        return Dictionary(
            uniqueKeysWithValues: fixtures.map { ($0.id, $0) }
        )
    }

    private func makeLeagueResult(
        pick: Pick,
        gameweek: Gameweek,
        fixtureMap: [Int: Fixture],
        leagueNames: [String: String]
    ) -> LeagueResult? {
        guard let fixture = fixtureMap[pick.fixtureId],
              let name = leagueNames[pick.leagueId] else {
            return nil
        }
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
