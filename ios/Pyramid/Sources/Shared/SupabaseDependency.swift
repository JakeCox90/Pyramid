import Foundation
import Supabase

/// UserDefaults-based auth storage — avoids keychain issues on the iOS Simulator.
private struct UserDefaultsAuthStorage: AuthLocalStorage, Sendable {
    func store(key: String, value: Data) throws {
        UserDefaults.standard.set(value, forKey: key)
    }

    func retrieve(key: String) throws -> Data? {
        UserDefaults.standard.data(forKey: key)
    }

    func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

/// Singleton Supabase client.
/// In tests, replace with a mock via dependency injection — do not use this directly in ViewModels.
final class SupabaseDependency: @unchecked Sendable {
    static let shared = SupabaseDependency()

    let client: SupabaseClient

    private static let supabaseURL: String = {
        guard let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              !value.isEmpty else {
            fatalError("SUPABASE_URL not set in Info.plist — check your .xcconfig")
        }
        return "https://\(value)"
    }()

    private static let supabaseAnonKey: String = {
        guard let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !value.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not set in Info.plist — check your .xcconfig")
        }
        return value
    }()

    private init() {
        guard let url = URL(string: Self.supabaseURL) else {
            fatalError("Invalid SUPABASE_URL")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Self.supabaseAnonKey,
            options: .init(
                auth: .init(
                    storage: UserDefaultsAuthStorage(),
                    flowType: .pkce
                )
            )
        )
    }
}
