import Foundation
import Supabase

// MARK: - Error

enum StandingsServiceError: LocalizedError, Equatable {
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol StandingsServiceProtocol: Sendable {
    func fetchMembers(leagueId: String) async throws -> [LeagueMember]
    func fetchLockedPicks(leagueId: String, gameweekId: Int) async throws -> [MemberPick]
}

// MARK: - Implementation

final class StandingsService: StandingsServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchMembers(leagueId: String) async throws -> [LeagueMember] {
        do {
            let members: [LeagueMember] = try await client
                .from("league_members")
                .select("""
                    id, user_id, status, joined_at,
                    eliminated_at, eliminated_in_gameweek_id,
                    profiles(username, display_name)
                """)
                .eq("league_id", value: leagueId)
                .order("joined_at", ascending: true)
                .execute()
                .value
            return members
        } catch {
            throw StandingsServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchLockedPicks(leagueId: String, gameweekId: Int) async throws -> [MemberPick] {
        do {
            let picks: [MemberPick] = try await client
                .from("picks")
                .select("user_id, team_name, result, is_locked, gameweek_id")
                .eq("league_id", value: leagueId)
                .eq("gameweek_id", value: gameweekId)
                .eq("is_locked", value: true)
                .execute()
                .value
            return picks
        } catch {
            throw StandingsServiceError.fetchFailed(error.localizedDescription)
        }
    }
}
