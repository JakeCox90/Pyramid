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

    /// Fetches player counts for all leagues concurrently.
    func fetchAllPlayerCounts(
        leagues: [League]
    ) async -> [String: PlayerCount] {
        await withTaskGroup(
            of: (String, PlayerCount).self
        ) { group in
            for league in leagues {
                group.addTask {
                    do {
                        let counts = try await self
                            .fetchPlayerCounts(
                                leagueId: league.id
                            )
                        return (league.id, counts)
                    } catch {
                        return (
                            league.id,
                            PlayerCount(active: 0, total: 0)
                        )
                    }
                }
            }
            var result: [String: PlayerCount] = [:]
            for await (id, count) in group {
                result[id] = count
            }
            return result
        }
    }
}
