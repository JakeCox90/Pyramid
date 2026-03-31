import SwiftUI

// MARK: - Gameweek State & Elimination Helpers

extension HomeViewModel {
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
        let results = homeData?.lastGwResults ?? []
        return results.first {
            $0.leagueId == league.id
                && $0.result == .eliminated
        }
    }

    /// The survival result for the given league from last GW.
    func survivalResult(
        for league: League
    ) -> LeagueResult? {
        guard !isEliminated(in: league) else {
            return nil
        }
        let results = homeData?.lastGwResults ?? []
        return results.first {
            $0.leagueId == league.id
                && $0.result == .survived
        }
    }
}

// MARK: - Gameweek Summary Builder

extension HomeViewModel {
    /// Builds summary items for all leagues that have settled results.
    func buildSummaryItems() -> [GameweekSummaryItem] {
        guard let data = homeData else { return [] }
        let results = data.lastGwResults

        return data.leagues.compactMap { league in
            // Find a result for this league (survived or eliminated)
            guard let result = results.first(where: {
                $0.leagueId == league.id
            }) else { return nil }

            let summaryResult: GameweekSummaryItem.SummaryResult
            switch result.result {
            case .survived:
                summaryResult = .survived
            case .eliminated:
                summaryResult = .eliminated
            default:
                return nil
            }

            let counts = data.playerCounts[league.id]
            let stats = data.eliminationStats[league.id]

            return GameweekSummaryItem(
                leagueId: league.id,
                leagueName: result.leagueName,
                result: summaryResult,
                pickedTeamName: result.teamName,
                opponentName: result.pickedHome
                    ? result.awayTeamName
                    : result.homeTeamName,
                homeTeamName: result.homeTeamName,
                homeTeamShort: result.homeTeamShort,
                homeTeamLogo: result.homeTeamLogo,
                awayTeamName: result.awayTeamName,
                awayTeamShort: result.awayTeamShort,
                awayTeamLogo: result.awayTeamLogo,
                homeScore: result.homeScore,
                awayScore: result.awayScore,
                pickedHome: result.pickedHome,
                survivalStreak: stats?.survivalStreak ?? 0,
                playersRemaining: counts?.active ?? 0,
                totalPlayers: counts?.total ?? 0
            )
        }
    }
}
