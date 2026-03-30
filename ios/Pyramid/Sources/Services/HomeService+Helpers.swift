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
                        return (
                            league.id,
                            PlayerCount(
                                active: counts.active,
                                total: counts.total
                            )
                        )
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

    /// Fetches member summaries for all leagues concurrently.
    func fetchAllMemberSummaries(
        leagues: [League]
    ) async -> [String: [MemberSummary]] {
        await withTaskGroup(
            of: (String, [MemberSummary]).self
        ) { group in
            for league in leagues {
                group.addTask {
                    do {
                        let summaries = try await self
                            .fetchMemberSummaries(
                                leagueId: league.id
                            )
                        return (league.id, summaries)
                    } catch {
                        return (league.id, [])
                    }
                }
            }
            var result: [String: [MemberSummary]] = [:]
            for await (id, summaries) in group {
                result[id] = summaries
            }
            return result
        }
    }

    /// Fetches elimination stats for all leagues concurrently.
    func fetchAllEliminationStats(
        userId: String,
        leagues: [League],
        gameweekId: Int?
    ) async -> [String: EliminationStats] {
        guard let gwId = gameweekId else { return [:] }
        return await withTaskGroup(
            of: (String, EliminationStats).self
        ) { group in
            for league in leagues {
                group.addTask {
                    do {
                        async let eliminated = self
                            .fetchEliminatedThisWeek(
                                leagueId: league.id,
                                gameweekId: gwId
                            )
                        async let streak = self
                            .fetchSurvivalStreak(
                                userId: userId,
                                leagueId: league.id
                            )
                        async let elimGwId = self
                            .fetchEliminatedGameweekId(
                                userId: userId,
                                leagueId: league.id
                            )
                        return (
                            league.id,
                            EliminationStats(
                                eliminatedThisWeek:
                                    try await eliminated,
                                survivalStreak:
                                    try await streak,
                                eliminatedGameweekId:
                                    try await elimGwId
                            )
                        )
                    } catch {
                        return (
                            league.id,
                            EliminationStats(
                                eliminatedThisWeek: 0,
                                survivalStreak: 0,
                                eliminatedGameweekId: nil
                            )
                        )
                    }
                }
            }
            var result: [String: EliminationStats] = [:]
            for await (id, stats) in group {
                result[id] = stats
            }
            return result
        }
    }
}
