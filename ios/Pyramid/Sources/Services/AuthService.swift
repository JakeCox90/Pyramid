import Foundation
import Supabase

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
}

final class AuthService: AuthServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}
