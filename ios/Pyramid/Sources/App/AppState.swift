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
    @Published var loadError: String?

    let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseDependency.shared.client
    }

    func loadSession() async {
        isLoading = true
        loadError = nil
        do {
            let session = try await withTimeout(seconds: 10) {
                try await self.supabase.auth.session
            }
            self.session = session
            Log.auth.info(
                "Session loaded: user=\(self.session?.user.id.uuidString.prefix(8) ?? "nil")"
            )
            if let userId = session.user.id.uuidString as String? {
                CrashReporter.setUser(id: userId)
            }
            checkOnboardingStatus()
        } catch is TimeoutError {
            Log.auth.error("Session load timed out")
            loadError = "Check your internet connection and try again."
        } catch {
            Log.auth.error("Session load failed: \(error.localizedDescription)")
            // A missing session means the user isn't signed in — not an error.
            // Only show the error screen for genuine failures (network, etc.).
            let isSessionMissing = error.localizedDescription.lowercased().contains("session missing")
                || error.localizedDescription.lowercased().contains("session not found")
            if !isSessionMissing {
                loadError = "Your session has expired. Please sign in again."
            }
            session = nil
        }
        isLoading = false

        listenForAuthChanges()
    }

    func retryLoadSession() async {
        loadError = nil
        isLoading = true
        await loadSession()
    }

    func completeOnboarding() {
        guard let userId = session?.user.id.uuidString else { return }
        UserDefaults.standard.set(true, forKey: onboardingKey(for: userId))
        showOnboarding = false
    }

    #if DEBUG
    func resetToOnboarding() {
        guard let userId = session?.user.id.uuidString else { return }
        UserDefaults.standard.set(false, forKey: onboardingKey(for: userId))
        showOnboarding = true
    }
    #endif

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
                    if let userId = session?.user.id.uuidString {
                        CrashReporter.setUser(id: userId)
                    }
                    self.checkOnboardingStatus()
                } else if event == .signedOut {
                    CrashReporter.clearUser()
                }
            }
        }
    }

    // MARK: - Timeout helpers

    private struct TimeoutError: Error {}

    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
