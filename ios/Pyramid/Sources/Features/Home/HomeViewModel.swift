import SwiftUI

// MARK: - Countdown Components

struct CountdownComponents: Equatable {
    let days: String
    let hours: String
    let minutes: String
    let seconds: String
    let isExpired: Bool

    static let zero = CountdownComponents(
        days: "0", hours: "00",
        minutes: "00", seconds: "00",
        isExpired: true
    )
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var homeData: HomeData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var countdown = CountdownComponents.zero
    @Published var selectedGameweek: Gameweek?
    @Published var selectedGwPicks: [LeagueResult] = []

    let homeService: HomeServiceProtocol
    var pollingTask: Task<Void, Never>?
    var timerTask: Task<Void, Never>?

    init(
        homeService: HomeServiceProtocol = HomeService()
    ) {
        self.homeService = homeService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            homeData = try await homeService.fetchHomeData()
            selectedGameweek = homeData?.gameweek
            updatePolling()
            startCountdown()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    // MARK: - Computed State

    /// The user's current pick paired with its fixture.
    var currentPick: LivePickContext? {
        guard let data = homeData else { return nil }
        let leagueMap = Dictionary(
            uniqueKeysWithValues: data.leagues.map {
                ($0.id, $0.name)
            }
        )
        return data.picks.values.compactMap { pick in
            guard let fixture = data.fixtures[pick.fixtureId],
                  let name = leagueMap[pick.leagueId]
            else { return nil }
            return LivePickContext(
                pick: pick, fixture: fixture,
                leagueName: name
            )
        }.first
    }

    var playersRemaining: String {
        guard let data = homeData,
              data.totalPlayerCount > 0
        else { return "" }
        return "\(data.activePlayerCount) of \(data.totalPlayerCount)"
    }

    var gameweekOptions: [Gameweek] {
        homeData?.allGameweeks ?? []
    }

    var livePickContexts: [LivePickContext] {
        guard let data = homeData else { return [] }
        let leagueMap = Dictionary(
            uniqueKeysWithValues: data.leagues.map {
                ($0.id, $0.name)
            }
        )
        return data.picks.values.compactMap { pick in
            guard let fixture = data.fixtures[pick.fixtureId],
                  fixture.status.isLive,
                  let name = leagueMap[pick.leagueId]
            else { return nil }
            return LivePickContext(
                pick: pick, fixture: fixture,
                leagueName: name
            )
        }
    }

    var hasLiveFixtures: Bool {
        homeData?.fixtures.values.contains {
            $0.status.isLive
        } ?? false
    }

    /// Gameweek is locked once the deadline has passed
    var isGameweekLocked: Bool {
        guard let deadline = homeData?.gameweek?.deadlineAt
        else { return false }
        return deadline <= Date()
    }

    /// Previous pick results for the current or selected GW.
    var previousPicks: [LeagueResult] {
        if selectedGameweek?.id == homeData?.gameweek?.id {
            return homeData?.lastGwResults ?? []
        }
        return selectedGwPicks
    }
}
