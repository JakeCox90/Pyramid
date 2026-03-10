import os
import SwiftUI
import Supabase

/// Top-level application state. Injected via .environmentObject.
/// Owns auth session — all other ViewModels read from here.
@MainActor
final class AppState: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true

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
        } catch {
            Log.auth.error("Session load failed: \(error.localizedDescription)")
            session = nil
        }
        isLoading = false

        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        Task { [weak self] in
            guard let self else { return }
            for await (event, session) in self.supabase.auth.authStateChanges {
                Log.auth.info("Auth event: \(event.rawValue)")
                self.session = session
            }
        }
    }
}
