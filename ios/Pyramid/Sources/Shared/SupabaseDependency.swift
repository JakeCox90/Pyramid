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

    // swiftlint:disable line_length
    #if DEBUG
    private static let supabaseURL = "https://qvmzmeizluqcdkcjsqyd.supabase.co"
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2bXptZWl6bHVxY2RrY2pzcXlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MDUxNzQsImV4cCI6MjA4ODQ4MTE3NH0.qi76NTlrxrW9CTHn7Y8pahEC0bpnkjF_R9u8eoIVaoo"
    #else
    private static let supabaseURL = "https://cracvbokmvryhhclzxxw.supabase.co"
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNyYWN2Ym9rbXZyeWhoY2x6eHh3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI5MDUyODAsImV4cCI6MjA4ODQ4MTI4MH0.khHYUW_xHJk1mLGKB0COQImANCg8Y00EW8gxJi39YJo"
    #endif
    // swiftlint:enable line_length

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
                    flowType: .implicit
                )
            )
        )
    }
}
