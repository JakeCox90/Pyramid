import SwiftUI

@MainActor
final class PickHistoryViewModel: ObservableObject {
    @Published var picks: [Pick] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let leagueId: String
    private let pickService: PickServiceProtocol

    init(leagueId: String, pickService: PickServiceProtocol = PickService()) {
        self.leagueId = leagueId
        self.pickService = pickService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            picks = try await pickService.fetchMyPickHistory(leagueId: leagueId)
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    var usedTeamIds: Set<Int> {
        Set(picks.map(\.teamId))
    }
}
