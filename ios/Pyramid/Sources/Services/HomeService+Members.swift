import Foundation
import Supabase

// MARK: - League Stats (via Edge Function)

extension HomeService {
    /// Fetches all league stats in a single edge function call.
    /// Replaces 5N individual queries with one batched request.
    func fetchLeagueStats(
        leagueIds: [String],
        currentGameweekId: Int?
    ) async throws -> LeagueStatsResponse {
        let body = LeagueStatsRequest(
            leagueIds: leagueIds,
            currentGameweekId: currentGameweekId
        )
        let response: LeagueStatsResponse =
            try await client.functions.invoke(
                "get-league-stats",
                options: FunctionInvokeOptions(
                    body: body
                )
            )
        return response
    }
}

// MARK: - Request / Response Types

private struct LeagueStatsRequest: Encodable {
    let leagueIds: [String]
    let currentGameweekId: Int?

    enum CodingKeys: String, CodingKey {
        case leagueIds = "league_ids"
        case currentGameweekId = "current_gameweek_id"
    }
}

struct LeagueStatsResponse: Decodable {
    let leagues: [String: LeagueStatsEntry]
}

struct LeagueStatsEntry: Decodable {
    let playerCounts: PlayerCountEntry
    let memberSummaries: [MemberSummaryEntry]
    let eliminationStats: EliminationStatsEntry

    enum CodingKeys: String, CodingKey {
        case playerCounts = "player_counts"
        case memberSummaries = "member_summaries"
        case eliminationStats = "elimination_stats"
    }
}

struct PlayerCountEntry: Decodable {
    let active: Int
    let total: Int
}

struct MemberSummaryEntry: Decodable {
    let userId: String
    let displayName: String
    let avatarUrl: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case status
    }
}

struct EliminationStatsEntry: Decodable {
    let eliminatedThisWeek: Int
    let survivalStreak: Int
    let eliminatedGameweekId: Int?

    enum CodingKeys: String, CodingKey {
        case eliminatedThisWeek = "eliminated_this_week"
        case survivalStreak = "survival_streak"
        case eliminatedGameweekId = "eliminated_gameweek_id"
    }
}

// MARK: - Mapping to Domain Models

extension LeagueStatsResponse {
    func toPlayerCounts() -> [String: PlayerCount] {
        var result: [String: PlayerCount] = [:]
        for (id, entry) in leagues {
            result[id] = PlayerCount(
                active: entry.playerCounts.active,
                total: entry.playerCounts.total
            )
        }
        return result
    }

    func toMemberSummaries() -> [String: [MemberSummary]] {
        var result: [String: [MemberSummary]] = [:]
        for (id, entry) in leagues {
            result[id] = entry.memberSummaries.map {
                let status = LeagueMember.MemberStatus(
                    rawValue: $0.status
                )
                if status == nil {
                    Log.home.warning(
                        "Unknown member status '\($0.status)' for user \($0.userId) — defaulting to .eliminated"
                    )
                }
                return MemberSummary(
                    userId: $0.userId,
                    displayName: $0.displayName,
                    avatarURL: $0.avatarUrl,
                    status: status ?? .eliminated
                )
            }
        }
        return result
    }

    func toEliminationStats() -> [String: EliminationStats] {
        var result: [String: EliminationStats] = [:]
        for (id, entry) in leagues {
            result[id] = EliminationStats(
                eliminatedThisWeek: entry
                    .eliminationStats
                    .eliminatedThisWeek,
                survivalStreak: entry
                    .eliminationStats
                    .survivalStreak,
                eliminatedGameweekId: entry
                    .eliminationStats
                    .eliminatedGameweekId
            )
        }
        return result
    }
}
