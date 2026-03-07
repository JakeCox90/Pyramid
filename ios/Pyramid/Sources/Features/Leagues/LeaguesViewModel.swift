import SwiftUI

@MainActor
final class LeaguesViewModel: ObservableObject {
    @Published var leagues: [League] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let leagueService: LeagueServiceProtocol

    init(leagueService: LeagueServiceProtocol = LeagueService()) {
        self.leagueService = leagueService
    }

    func fetchLeagues() async {
        isLoading = true
        errorMessage = nil
        do {
            leagues = try await leagueService.fetchMyLeagues()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func leagueAdded(_ response: CreateLeagueResponse) async {
        // Refresh full list to pick up the newly created league
        await fetchLeagues()
    }
}
