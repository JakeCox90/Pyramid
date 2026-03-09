import Foundation
import Supabase

/// Singleton Supabase client. Initialised once from environment / Info.plist.
/// In tests, replace with a mock via dependency injection — do not use this directly in ViewModels.
final class SupabaseDependency: @unchecked Sendable {
    static let shared = SupabaseDependency()

    let client: SupabaseClient

    private init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""

        guard let url = URL(string: urlString), !urlString.isEmpty, !anonKey.isEmpty else {
            // Placeholder client for test runner — real app requires valid xcconfig values
            client = SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder"
            )
            return
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
