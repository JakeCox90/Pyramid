import Foundation
import Supabase

protocol LeaderboardServiceProtocol: Sendable {
    func fetchLeaderboard(limit: Int) async throws -> [LeaderboardEntry]
}

final class LeaderboardService: LeaderboardServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        try await client
            .rpc("get_leaderboard", params: ["limit_count": limit])
            .execute()
            .value
    }
}
