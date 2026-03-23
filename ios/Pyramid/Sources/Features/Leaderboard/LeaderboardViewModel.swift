import Foundation

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: LeaderboardServiceProtocol

    init(service: LeaderboardServiceProtocol = LeaderboardService()) {
        self.service = service
    }

    func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await service.fetchLeaderboard(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
