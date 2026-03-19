import os
import SwiftUI

@MainActor
final class BrowseLeaguesViewModel: ObservableObject {
    @Published var leagues: [BrowseLeague] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var joiningLeagueId: String?
    @Published var joinedLeague: JoinLeagueResponse?

    private let leagueService: LeagueServiceProtocol

    init(leagueService: LeagueServiceProtocol = LeagueService()) {
        self.leagueService = leagueService
    }

    func fetchOpenLeagues() async {
        isLoading = true
        errorMessage = nil
        do {
            leagues = try await leagueService.fetchOpenLeagues()
        } catch {
            Log.leagues.error("Fetch open leagues failed: \(error.localizedDescription)")
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func joinLeague(_ league: BrowseLeague) async {
        joiningLeagueId = league.id
        do {
            let response = try await leagueService.joinLeague(code: league.joinCode)
            joinedLeague = response
            leagues.removeAll { $0.id == league.id }
        } catch {
            Log.leagues.error("Join league failed: \(error.localizedDescription)")
            errorMessage = AppError.from(error).userMessage
        }
        joiningLeagueId = nil
    }
}
