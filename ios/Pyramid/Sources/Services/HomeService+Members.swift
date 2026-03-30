import Foundation
import Supabase

// MARK: - Member Summaries & Elimination Stats

extension HomeService {
    /// Fetches lightweight member summaries for avatar display.
    func fetchMemberSummaries(
        leagueId: String
    ) async throws -> [MemberSummary] {
        let rows: [MemberSummaryRow] = try await client
            .from("league_members")
            .select("""
                user_id, status, \
                profiles(username, display_name, avatar_url)
                """)
            .eq("league_id", value: leagueId)
            .execute()
            .value

        return rows.map { row in
            MemberSummary(
                userId: row.userId,
                displayName: row.profiles.displayLabel,
                avatarURL: row.profiles.avatarUrl,
                status: row.status
            )
        }
    }

    /// Counts members eliminated in the current gameweek.
    func fetchEliminatedThisWeek(
        leagueId: String,
        gameweekId: Int
    ) async throws -> Int {
        let rows: [EliminatedCheckRow] = try await client
            .from("league_members")
            .select("id")
            .eq("league_id", value: leagueId)
            .eq("status", value: "eliminated")
            .eq("eliminated_in_gameweek_id", value: gameweekId)
            .execute()
            .value

        return rows.count
    }

    /// Counts consecutive survived picks for a user in a league,
    /// walking backwards from the most recent settled gameweek.
    func fetchSurvivalStreak(
        userId: String,
        leagueId: String
    ) async throws -> Int {
        let picks: [StreakPickRow] = try await client
            .from("picks")
            .select("result, gameweek_id")
            .eq("user_id", value: userId)
            .eq("league_id", value: leagueId)
            .neq("result", value: "pending")
            .order("gameweek_id", ascending: false)
            .execute()
            .value

        var streak = 0
        for pick in picks {
            if pick.result == .survived {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Private Row Types

private struct MemberSummaryRow: Decodable {
    let userId: String
    let status: LeagueMember.MemberStatus
    let profiles: ProfileRow

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case profiles
    }

    struct ProfileRow: Decodable {
        let username: String
        let displayName: String?
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case username
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }

        var displayLabel: String {
            displayName ?? username
        }
    }
}

private struct EliminatedCheckRow: Decodable {
    let id: String
}

private struct StreakPickRow: Decodable {
    let result: PickResult
    let gameweekId: Int

    enum CodingKeys: String, CodingKey {
        case result
        case gameweekId = "gameweek_id"
    }
}
