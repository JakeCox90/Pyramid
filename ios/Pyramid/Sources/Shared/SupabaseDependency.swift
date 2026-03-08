import Foundation
import Supabase

/// Singleton Supabase client. Initialised once from environment / Info.plist.
/// In tests, replace with a mock via dependency injection — do not use this directly in ViewModels.
final class SupabaseDependency: @unchecked Sendable {
    static let shared = SupabaseDependency()

    let client: SupabaseClient

    private init() {
        let scheme = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL_SCHEME") as? String ?? ""
        let host = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL_HOST") as? String ?? ""
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""

        guard !scheme.isEmpty, !host.isEmpty, let url = URL(string: "\(scheme)://\(host)"), !anonKey.isEmpty else {
            fatalError(
                "SUPABASE_URL_SCHEME, SUPABASE_URL_HOST and SUPABASE_ANON_KEY must be set in Info.plist via xcconfig"
            )
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}
