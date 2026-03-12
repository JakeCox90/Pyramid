import Foundation
import os
import UserNotifications
import UIKit
import Supabase

// MARK: - Deep Link Screen

enum DeepLinkScreen: String {
    case picks
    case standings
    case wallet
    case settlement
}

// MARK: - Deep Link Payload

struct DeepLinkPayload {
    let screen: DeepLinkScreen
    let leagueId: String?
    let gameweekId: Int?
}

extension Notification.Name {
    static let navigateToScreen = Notification.Name("navigateToScreen")
    static let navigateWithPayload = Notification.Name("navigateWithPayload")
}

// MARK: - Edge Function Body

private struct RegisterDeviceTokenBody: Encodable {
    let token: String
    let platform: String
}

// MARK: - NotificationService

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isPermissionGranted = false
    @Published var deviceToken: String?

    private let client: SupabaseClient

    private override init() {
        self.client = SupabaseDependency.shared.client
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Call this at first paid league join attempt — NOT at app launch (rules §PRD-003)
    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            isPermissionGranted = settings.authorizationStatus == .authorized
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isPermissionGranted = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            isPermissionGranted = false
        }
    }

    /// Called by AppDelegate when APNs assigns a token
    func handleDeviceToken(_ data: Data) async {
        let tokenString = data.map { String(format: "%02.2hhx", $0) }.joined()
        Log.notifications.info("APNs token received, registering with server")
        deviceToken = tokenString
        await registerToken(tokenString)
    }

    /// Called by AppDelegate on registration failure
    func handleRegistrationFailure(_ error: Error) {
        // Log failure without crashing — token registration is best-effort
        Log.notifications.error("APNs registration failed: \(error.localizedDescription)")
    }

    /// Routes a notification deep link to the correct screen
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard let screenValue = userInfo["screen"] as? String,
              let screen = DeepLinkScreen(rawValue: screenValue) else { return }

        let leagueId = userInfo["league_id"] as? String
        let gameweekId: Int?
        if let gwValue = userInfo["gameweek_id"] as? Int {
            gameweekId = gwValue
        } else if let gwString = userInfo["gameweek_id"] as? String {
            gameweekId = Int(gwString)
        } else {
            gameweekId = nil
        }

        let payload = DeepLinkPayload(screen: screen, leagueId: leagueId, gameweekId: gameweekId)
        NotificationCenter.default.post(name: .navigateWithPayload, object: payload)

        // Also post legacy notification for backwards compatibility
        NotificationCenter.default.post(name: .navigateToScreen, object: screenValue)
    }

    // MARK: - Private

    private func registerToken(_ tokenString: String) async {
        do {
            try await client.functions.invoke(
                "register-device-token",
                options: FunctionInvokeOptions(
                    body: RegisterDeviceTokenBody(token: tokenString, platform: "ios")
                )
            )
        } catch {
            Log.notifications.error("Failed to register device token: \(error.localizedDescription)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
