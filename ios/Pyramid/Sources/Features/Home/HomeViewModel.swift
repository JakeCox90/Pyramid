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
    @Published var showGameweekSummary = false
    @Published var gameweekSummaryItems: [GameweekSummaryItem] = []
    @Published var summaryStartIndex: Int = 0

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
            // Build gameweek summary and auto-show if first time
            gameweekSummaryItems = buildSummaryItems()
            if gameweekPhase == .finished,
               !gameweekSummaryItems.isEmpty,
               let gwId = homeData?.gameweek?.id {
                let key = "gw_summary_seen_\(gwId)"
                if !UserDefaults.standard.bool(forKey: key) {
                    UserDefaults.standard.set(true, forKey: key)
                    summaryStartIndex = 0
                    showGameweekSummary = true
                }
            }
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func selectLeague(_ league: League) {
        selectedLeague = league
    }

    /// Opens the Gameweek Summary overlay scrolled to a specific league.
    func showSummary(for leagueId: String) {
        if let index = gameweekSummaryItems.firstIndex(
            where: { $0.leagueId == leagueId }
        ) {
            summaryStartIndex = index
        }
        showGameweekSummary = true
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
                leagueName: league.name,
                memberStatus: data.memberStatuses[league.id]
            )
        }
        #endif

        guard let pick = data.picks[league.id],
              let fixture = data.fixtures[pick.fixtureId]
        else { return nil }
        return LivePickContext(
            pick: pick, fixture: fixture,
            leagueName: league.name,
            memberStatus: data.memberStatuses[league.id]
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

    /// The authenticated user's ID from the last home data fetch.
    var currentUserId: String {
        homeData?.userId ?? ""
    }

    func memberSummaries(
        for league: League
    ) -> [MemberSummary] {
        homeData?.memberSummaries[league.id] ?? []
    }

    func eliminationStats(
        for league: League
    ) -> EliminationStats? {
        homeData?.eliminationStats[league.id]
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
            leagueName: league.name,
            memberStatus: data.memberStatuses[league.id]
        )]
    }

    var hasLiveFixtures: Bool {
        homeData?.fixtures.values.contains {
            $0.status.isLive
        } ?? false
    }

}
