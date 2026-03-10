import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isSigningOut = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    /// Signs the user out. Returns `true` on success so the caller can clear `AppState.session`.
    func signOut() async -> Bool {
        isSigningOut = true
        errorMessage = nil
        do {
            try await authService.signOut()
            isSigningOut = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSigningOut = false
            return false
        }
    }
}
