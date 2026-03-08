import SwiftUI
import Supabase

/// Top-level application state. Injected via .environmentObject.
/// Owns auth session — all other ViewModels read from here.
@MainActor
final class AppState: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true

    let supabase: SupabaseClient = SupabaseDependency.shared.client

    func loadSession() async {
        for await (_, session) in supabase.auth.authStateChanges {
            self.session = session
            self.isLoading = false
        }
    }
}
