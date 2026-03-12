import Foundation
import os
import Supabase

// MARK: - Error

enum ProfileServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

// MARK: - Query helpers

private struct MemberWithLeagueRow: Decodable {
    let leagueId: String
    let status: MemberStatus
    let eliminatedInGameweekId: Int?
    let leagues: LeagueRow

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case status
        case eliminatedInGameweekId = "eliminated_in_gameweek_id"
        case leagues
    }

    enum MemberStatus: String, Decodable {
        case active
        case eliminated
        case winner
    }

    struct LeagueRow: Decodable {
        let id: String
        let name: String
        let status: LeagueRowStatus
        let season: Int

        enum LeagueRowStatus: String, Decodable {
            case pending
            case active
            case completed
            case cancelled
        }
    }
}

// MARK: - Protocol

protocol ProfileServiceProtocol: Sendable {
    func fetchProfileStats() async throws -> ProfileStats
}

// MARK: - Implementation

final class ProfileService: ProfileServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchProfileStats() async throws -> ProfileStats {
        do {
            let userId = try await client.auth.session.user.id.uuidString

            // Query 1: league memberships with embedded league info
            let memberRows: [MemberWithLeagueRow] = try await client
                .from("league_members")
                .select("league_id, status, eliminated_in_gameweek_id, leagues(id, name, status, season)")
                .eq("user_id", value: userId)
                .execute()
                .value

            // Query 2: all picks for this user ordered by league + gameweek
            let pickColumns = [
                "id", "league_id", "user_id", "gameweek_id",
                "fixture_id", "team_id", "team_name",
                "is_locked", "result", "submitted_at"
            ].joined(separator: ", ")
            let picks: [Pick] = try await client
                .from("picks")
                .select(pickColumns)
                .eq("user_id", value: userId)
                .order("league_id", ascending: true)
                .order("gameweek_id", ascending: true)
                .execute()
                .value

            return buildStats(memberRows: memberRows, picks: picks)
        } catch let error as ProfileServiceError {
            throw error
        } catch {
            Log.network.error("ProfileService.fetchProfileStats failed: \(error)")
            throw ProfileServiceError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Private helpers

    private func buildStats(
        memberRows: [MemberWithLeagueRow],
        picks: [Pick]
    ) -> ProfileStats {
        let totalLeaguesJoined = memberRows.count
        let wins = memberRows.filter { $0.status == .winner }.count

        let totalPicksMade = picks.count
        let longestStreak = calculateLongestStreak(picks: picks)

        let picksByLeague = Dictionary(grouping: picks, by: \.leagueId)

        let activeStreaks: [LeagueStreak] = memberRows
            .filter { $0.leagues.status == .active }
            .compactMap { member in
                let leaguePicks = (picksByLeague[member.leagueId] ?? [])
                    .sorted { $0.gameweekId > $1.gameweekId }
                let streak = consecutiveSurvivedFromStart(picks: leaguePicks)
                guard streak > 0 else { return nil }
                return LeagueStreak(
                    id: member.leagueId,
                    leagueName: member.leagues.name,
                    currentStreak: streak
                )
            }
            .sorted { $0.currentStreak > $1.currentStreak }

        let leagueHistory: [CompletedLeague] = memberRows
            .filter { $0.leagues.status == .completed }
            .map { member in
                let result: CompletedLeagueResult = member.status == .winner ? .winner : .eliminated
                return CompletedLeague(
                    id: member.leagueId,
                    leagueName: member.leagues.name,
                    result: result,
                    eliminatedGameweek: member.eliminatedInGameweekId,
                    season: member.leagues.season
                )
            }

        return ProfileStats(
            totalLeaguesJoined: totalLeaguesJoined,
            wins: wins,
            totalPicksMade: totalPicksMade,
            longestSurvivalStreak: longestStreak,
            activeStreaks: activeStreaks,
            leagueHistory: leagueHistory
        )
    }

    /// Longest consecutive `.survived` streak across all picks regardless of league.
    private func calculateLongestStreak(picks: [Pick]) -> Int {
        var longest = 0
        var current = 0
        for pick in picks {
            if pick.result == .survived {
                current += 1
                longest = max(longest, current)
            } else if pick.result != .pending {
                current = 0
            }
        }
        return longest
    }

    /// Count consecutive `.survived` picks from the most recent (picks already sorted desc by gameweek).
    private func consecutiveSurvivedFromStart(picks: [Pick]) -> Int {
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
