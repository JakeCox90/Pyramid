import Foundation
import Supabase

// MARK: - Home Data Helpers

extension HomeService {
    func fetchPicksAndFixtures(
        userId: String,
        gameweek: Gameweek?,
        leagueIds: [String]
    ) async throws -> ([String: Pick], [Int: Fixture]) {
        guard let gw = gameweek else { return ([:], [:]) }
        async let picksFetch = fetchPicks(
            userId: userId, gameweekId: gw.id,
            leagueIds: leagueIds
        )
        async let fixturesFetch = fetchFixtures(
            gameweekId: gw.id
        )
        let picks = try await picksFetch
        let list = try await fixturesFetch
        let fixtures = Dictionary(
            uniqueKeysWithValues: list.map { ($0.id, $0) }
        )
        return (picks, fixtures)
    }

    func fetchResults(
        userId: String,
        lastGw: Gameweek?,
        leagueIds: [String],
        leagueNames: [String: String]
    ) async throws -> [LeagueResult] {
        guard let lastGw, !leagueIds.isEmpty else { return [] }
        return try await fetchLastGwResults(
            userId: userId, gameweek: lastGw,
            leagueIds: leagueIds, leagueNames: leagueNames
        )
    }

    /// Fetches all league stats in a single edge function call.
    func fetchAllLeagueStats(
        leagueIds: [String],
        gameweekId: Int?
    ) async -> LeagueStatsResponse? {
        guard !leagueIds.isEmpty else { return nil }
        do {
            return try await fetchLeagueStats(
                leagueIds: leagueIds,
                currentGameweekId: gameweekId
            )
        } catch {
            Log.home.error(
                "League stats fetch failed: \(error)"
            )
            return nil
        }
    }
}
