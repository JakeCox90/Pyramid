import Foundation
import Supabase

// MARK: - Protocol

protocol NotificationPreferencesServiceProtocol: Sendable {
    func fetchPreferences() async throws -> NotificationPreferences
    func updatePreferences(_ prefs: NotificationPreferences) async throws
}

// MARK: - Upsert Row

private struct NotificationPreferencesRow: Codable {
    let userId: String
    var deadlineReminders: Bool
    var pickLocked: Bool
    var resultAlerts: Bool
    var winningsAlerts: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deadlineReminders = "deadline_reminders"
        case pickLocked = "pick_locked"
        case resultAlerts = "result_alerts"
        case winningsAlerts = "winnings_alerts"
    }
}

// MARK: - Implementation

final class NotificationPreferencesService: NotificationPreferencesServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchPreferences() async throws -> NotificationPreferences {
        let rows: [NotificationPreferences] = try await client
            .from("notification_preferences")
            .select("deadline_reminders, pick_locked, result_alerts, winnings_alerts")
            .limit(1)
            .execute()
            .value
        return rows.first ?? .defaultPreferences
    }

    func updatePreferences(_ prefs: NotificationPreferences) async throws {
        let userId = try await client.auth.session.user.id.uuidString
        let row = NotificationPreferencesRow(
            userId: userId,
            deadlineReminders: prefs.deadlineReminders,
            pickLocked: prefs.pickLocked,
            resultAlerts: prefs.resultAlerts,
            winningsAlerts: prefs.winningsAlerts
        )
        try await client
            .from("notification_preferences")
            .upsert(row, onConflict: "user_id")
            .execute()
    }
}
