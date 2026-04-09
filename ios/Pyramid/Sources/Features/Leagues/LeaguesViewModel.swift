import SwiftUI

@MainActor
final class LeaguesViewModel: ObservableObject {
    @Published var leagues: [League] = []
    @Published var activeLeagueCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let maxActiveLeagues = 5

    var isAtLeagueCap: Bool {
        activeLeagueCount >= Self.maxActiveLeagues
    }

    private let leagueService: LeagueServiceProtocol

    init(leagueService: LeagueServiceProtocol = LeagueService()) {
        self.leagueService = leagueService
    }

    func fetchLeagues() async {
        isLoading = true
        errorMessage = nil
        do {
            async let leaguesTask = leagueService.fetchMyLeagues()
            async let countTask = leagueService.fetchActiveLeagueCount()
            leagues = try await leaguesTask
            activeLeagueCount = try await countTask
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func leagueAdded(_ response: CreateLeagueResponse) async {
        await fetchLeagues()
    }
}
