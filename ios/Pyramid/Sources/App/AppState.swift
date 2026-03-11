import os
import SwiftUI
import Supabase

/// Top-level application state. Injected via .environmentObject.
/// Owns auth session — all other ViewModels read from here.
@MainActor
final class AppState: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true
    @Published var showOnboarding = false

    let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseDependency.shared.client
    }

    func loadSession() async {
        do {
            session = try await supabase.auth.session
            Log.auth.info(
                "Session loaded: user=\(self.session?.user.id.uuidString.prefix(8) ?? "nil")"
            )
            checkOnboardingStatus()
        } catch {
            Log.auth.error("Session load failed: \(error.localizedDescription)")
            session = nil
        }
        isLoading = false

        listenForAuthChanges()
    }

    func completeOnboarding() {
        guard let userId = session?.user.id.uuidString else { return }
        UserDefaults.standard.set(true, forKey: onboardingKey(for: userId))
        showOnboarding = false
    }

    private func checkOnboardingStatus() {
        guard let userId = session?.user.id.uuidString else { return }
        let completed = UserDefaults.standard.bool(forKey: onboardingKey(for: userId))
        showOnboarding = !completed
    }

    private func onboardingKey(for userId: String) -> String {
        "hasCompletedOnboarding_\(userId)"
    }

    private func listenForAuthChanges() {
        Task { [weak self] in
            guard let self else { return }
            for await (event, session) in self.supabase.auth.authStateChanges {
                Log.auth.info("Auth event: \(event.rawValue)")
                self.session = session
                if event == .signedIn {
                    self.checkOnboardingStatus()
                }
            }
        }
    }
}
