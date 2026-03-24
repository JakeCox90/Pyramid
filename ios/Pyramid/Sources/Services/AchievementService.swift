import Foundation
import Supabase

protocol AchievementServiceProtocol: Sendable {
    func fetchUnlocked() async throws -> [Achievement]
}

final class AchievementService: AchievementServiceProtocol {
    private let client: SupabaseClient

    init(
        client: SupabaseClient = SupabaseDependency.shared.client
    ) {
        self.client = client
    }

    func fetchUnlocked() async throws -> [Achievement] {
        try await client
            .from("user_achievements")
            .select("achievement_id, unlocked_at, context")
            .execute()
            .value
    }
}
