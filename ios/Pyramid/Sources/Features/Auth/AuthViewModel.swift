import os
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    #if DEBUG
    @Published var email = "test@pyramid.app"
    @Published var password = "Pyramid2026Dev"
    #else
    @Published var email = ""
    @Published var password = ""
    #endif
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    func signIn() async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(email: email, password: password)
            Log.auth.info("Sign-in succeeded for \(self.email)")
        } catch {
            Log.auth.error("Sign-in failed: \(String(describing: error))")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp() async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signUp(email: email, password: password)
            Log.auth.info("Sign-up succeeded for \(self.email)")
        } catch {
            Log.auth.error("Sign-up failed: \(String(describing: error))")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func validate() -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return false
        }
        return true
    }
}
