import AuthenticationServices
import Foundation
import Supabase

protocol AuthServiceProtocol: Sendable {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() async throws
    func signInWithApple(idToken: String, nonce: String) async throws
    func signInWithGoogle() async throws
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

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    /// Launches a Google sign-in via ASWebAuthenticationSession (PKCE flow).
    /// The Supabase SDK handles the full browser round-trip internally.
    func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "com.pyramid.app://login-callback")
        )
    }
}
