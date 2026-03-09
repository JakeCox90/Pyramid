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
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""

        guard let url = URL(string: urlString), !urlString.isEmpty, !anonKey.isEmpty else {
            // Use a placeholder client so the test runner can bootstrap the app
            // without crashing. Real app launch requires valid xcconfig values.
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder"
            )
            return
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
