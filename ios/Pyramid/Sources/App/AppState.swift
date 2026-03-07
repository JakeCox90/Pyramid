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
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        else {
            fatalError("SUPABASE_URL and SUPABASE_ANON_KEY must be set in Info.plist")
        }

        self.supabase = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    func loadSession() async {
        do {
            session = try await supabase.auth.session
        } catch {
            session = nil
        }
        isLoading = false
    }
}
