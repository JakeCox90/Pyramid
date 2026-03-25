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
    @Published var selectedLeague: League?

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
            // Preserve league selection if still valid, else default to first
            if let current = selectedLeague,
               homeData?.leagues.contains(where: { $0.id == current.id }) == true {
                // keep current selection
            } else {
                selectedLeague = homeData?.leagues.first
            }
            updatePolling()
            startCountdown()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func selectLeague(_ league: League) {
        selectedLeague = league
    }

    // MARK: - Computed State

    /// The user's current pick for the selected league.
    var currentPick: LivePickContext? {
        guard let league = selectedLeague
        else { return nil }
        return currentPick(for: league)
    }

    func currentPick(
        for league: League
    ) -> LivePickContext? {
        guard let data = homeData else { return nil }

        #if DEBUG
        if let fake = DebugGameweekOverride.fakePick(
               for: league.id
           ),
           let fixture = data.fixtures[fake.fixtureId] {
            let pick = Pick(
                id: "debug-fake",
                leagueId: fake.leagueId,
                userId: "debug",
                gameweekId: data.gameweek?.id ?? 0,
                fixtureId: fake.fixtureId,
                teamId: fake.teamId,
                teamName: fake.teamName,
                isLocked: false,
                result: .pending,
                submittedAt: Date()
            )
            return LivePickContext(
                pick: pick, fixture: fixture,
                leagueName: league.name
            )
        }
        #endif

        guard let pick = data.picks[league.id],
              let fixture = data.fixtures[pick.fixtureId]
        else { return nil }
        return LivePickContext(
            pick: pick, fixture: fixture,
            leagueName: league.name
        )
    }

    var playersRemaining: String {
        guard let league = selectedLeague
        else { return "" }
        return playersRemaining(for: league)
    }

    func playersRemaining(for league: League) -> String {
        guard let data = homeData,
              let counts = data.playerCounts[league.id],
              counts.total > 0
        else { return "" }
        return "\(counts.active) of \(counts.total)"
    }

    var gameweekOptions: [Gameweek] {
        homeData?.allGameweeks ?? []
    }

    var livePickContexts: [LivePickContext] {
        guard let data = homeData,
              let league = selectedLeague,
              let pick = data.picks[league.id],
              let fixture = data.fixtures[pick.fixtureId],
              fixture.status.isLive
        else { return [] }
        return [LivePickContext(
            pick: pick, fixture: fixture,
            leagueName: league.name
        )]
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
        #if DEBUG
        if DebugGameweekOverride.isActive {
            return DebugGameweekOverride.isLocked
        }
        #endif
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
        #if DEBUG
        if DebugGameweekOverride.isActive {
            switch DebugGameweekOverride.current {
            case .none: break
            case .upcoming: return .upcoming
            case .inProgress: return .inProgress
            case .finished: return .finished
            }
        }
        #endif
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

    /// Whether the user is eliminated in the given league.
    func isEliminated(
        in league: League
    ) -> Bool {
        #if DEBUG
        if DebugGameweekOverride.isDebugEliminated(
            leagueName: league.name
        ) {
            return true
        }
        #endif
        return homeData?.memberStatuses[league.id]
            == .eliminated
    }

    /// The elimination result for the given league, if the user
    /// was eliminated and we have match data for it.
    func eliminationResult(
        for league: League
    ) -> LeagueResult? {
        guard isEliminated(in: league) else {
            return nil
        }
        // Find the result that caused elimination
        // (result == .eliminated in lastGwResults)
        let results = homeData?.lastGwResults ?? []
        return results.first {
            $0.leagueId == league.id
                && $0.result == .eliminated
        }
    }

    /// Previous pick results for the current or selected GW,
    /// filtered to the selected league.
    var previousPicks: [LeagueResult] {
        guard let league = selectedLeague
        else { return [] }
        return previousPicks(for: league)
    }

    func previousPicks(
        for league: League
    ) -> [LeagueResult] {
        let all: [LeagueResult]
        if selectedGameweek?.id == homeData?.gameweek?.id {
            all = homeData?.lastGwResults ?? []
        } else {
            all = selectedGwPicks
        }
        return all.filter { $0.leagueId == league.id }
    }
}
