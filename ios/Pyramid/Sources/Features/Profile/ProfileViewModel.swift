import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isSigningOut = false
    @Published var isLoadingStats = false
    @Published var errorMessage: String?
    @Published var stats: ProfileStats = .empty

    private let authService: AuthServiceProtocol
    private let profileService: ProfileServiceProtocol

    init(
        authService: AuthServiceProtocol = AuthService(),
        profileService: ProfileServiceProtocol = ProfileService()
    ) {
        self.authService = authService
        self.profileService = profileService
    }

    func loadStats() async {
        isLoadingStats = true
        errorMessage = nil
        do {
            stats = try await profileService.fetchProfileStats()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoadingStats = false
    }

    func signOut() async -> Bool {
        isSigningOut = true
        errorMessage = nil
        do {
            try await authService.signOut()
            isSigningOut = false
            return true
        } catch {
            errorMessage = AppError.from(error).userMessage
            isSigningOut = false
            return false
        }
    }
}
