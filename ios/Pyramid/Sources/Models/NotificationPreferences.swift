import Foundation

struct NotificationPreferences: Codable {
    var deadlineReminders: Bool
    var pickLocked: Bool
    var resultAlerts: Bool
    var winningsAlerts: Bool

    enum CodingKeys: String, CodingKey {
        case deadlineReminders = "deadline_reminders"
        case pickLocked = "pick_locked"
        case resultAlerts = "result_alerts"
        case winningsAlerts = "winnings_alerts"
    }

    static var defaultPreferences: NotificationPreferences {
        NotificationPreferences(
            deadlineReminders: true,
            pickLocked: true,
            resultAlerts: true,
            winningsAlerts: true
        )
    }
}
