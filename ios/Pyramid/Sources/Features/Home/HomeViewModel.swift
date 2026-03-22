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

/// Describes the current phase of the gameweek
enum GameweekPhase: Equatable {
    /// Countdown is ticking — GW hasn't started
    case upcoming
    /// All fixtures are live or some are in progress
    case inProgress
    /// All fixtures have finished
    case finished
    /// No gameweek data available
    case unknown
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

    /// Gameweek is locked once the first fixture has kicked off.
    /// Rules §3.3: deadline = kick-off of the first match of the GW.
    /// We check both deadline_at AND actual fixture statuses as a
    /// belt-and-braces approach.
    var isGameweekLocked: Bool {
        // If any fixture is live or finished, the GW has started
        if let fixtures = homeData?.fixtures.values,
           fixtures.contains(where: {
               $0.status.isLive || $0.status.isFinished
           }) {
            return true
        }
        // Also check the earliest kickoff time across all fixtures
        if let fixtures = homeData?.fixtures.values,
           let earliest = fixtures.map(\.kickoffAt).min(),
           earliest <= Date() {
            return true
        }
        // Fallback to deadline_at (should equal first kickoff)
        if let deadline = homeData?.gameweek?.deadlineAt,
           deadline <= Date() {
            return true
        }
        return false
    }

    var gameweekPhase: GameweekPhase {
        guard let fixtures = homeData?.fixtures.values,
              !fixtures.isEmpty
        else { return .unknown }
        let allFinished = fixtures.allSatisfy {
            $0.status.isFinished
        }
        if allFinished { return .finished }
        let anyStarted = fixtures.contains {
            $0.status.isLive || $0.status.isFinished
        }
        if anyStarted || isGameweekLocked {
            return .inProgress
        }
        return .upcoming
    }

    /// Previous pick results for the current or selected GW.
    var previousPicks: [LeagueResult] {
        if selectedGameweek?.id == homeData?.gameweek?.id {
            return homeData?.lastGwResults ?? []
        }
        return selectedGwPicks
    }
}
