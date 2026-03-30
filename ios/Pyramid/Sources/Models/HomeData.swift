import Foundation

/// Per-league player count with optional elimination history.
struct PlayerCount: Sendable, Equatable {
    let active: Int
    let total: Int
    /// Eliminations per gameweek: [(gameweekId, eliminatedCount)], sorted by GW.
    let eliminationHistory: [EliminationSnapshot]

    init(active: Int, total: Int, eliminationHistory: [EliminationSnapshot] = []) {
        self.active = active
        self.total = total
        self.eliminationHistory = eliminationHistory
    }
}

/// A single gameweek's elimination count.
struct EliminationSnapshot: Sendable, Equatable, Identifiable {
    let gameweekId: Int
    let eliminated: Int
    var id: Int { gameweekId }
}

/// Aggregate data for the home screen, fetched in a single service call.
struct HomeData: Sendable, Equatable {
    /// User's leagues with member counts.
    let leagues: [League]
    /// Current gameweek, or nil if none is active.
    let gameweek: Gameweek?
    /// User's picks for the current gameweek, keyed by league ID.
    let picks: [String: Pick]
    /// User's member status per league, keyed by league ID.
    let memberStatuses: [String: LeagueMember.MemberStatus]
    /// Fixtures for the current gameweek, keyed by fixture ID.
    let fixtures: [Int: Fixture]
    /// User's settled results from the last finished gameweek.
    let lastGwResults: [LeagueResult]
    /// All gameweeks for the season (dropdown selector).
    let allGameweeks: [Gameweek]
    /// Player counts per league: (active, total), keyed by league ID.
    let playerCounts: [String: PlayerCount]
}

/// A user's pick paired with its fixture and league name for homepage display.
struct LivePickContext: Identifiable, Equatable {
    let pick: Pick
    let fixture: Fixture
    let leagueName: String
    /// The user's membership status in this league (active/eliminated/winner).
    var memberStatus: LeagueMember.MemberStatus?
    var id: String { pick.id }

    /// Whether the user is surviving based on live scores.
    /// Falls back to `memberStatus` when fixture scores are unavailable
    /// (e.g. during FT status transition edge cases).
    var isSurviving: Bool? {
        if fixture.status.isLive || fixture.status.isFinished {
            let homeScore = fixture.homeScore ?? 0
            let awayScore = fixture.awayScore ?? 0
            if pick.teamId == fixture.homeTeamId {
                return homeScore >= awayScore
            } else {
                return awayScore >= homeScore
            }
        }
        // Fallback: use league member status for settled state
        if let memberStatus {
            switch memberStatus {
            case .active, .winner:
                return true
            case .eliminated:
                return false
            }
        }
        return nil
    }
}

/// A single league result from a settled gameweek.
struct LeagueResult: Identifiable, Sendable, Equatable {
    let leagueId: String
    let leagueName: String
    let gameweekName: String
    let teamName: String
    let teamId: Int
    let result: PickResult
    let homeTeamId: Int
    let homeTeamName: String
    let homeTeamShort: String
    let homeTeamLogo: String?
    let awayTeamId: Int
    let awayTeamName: String
    let awayTeamShort: String
    let awayTeamLogo: String?
    let homeScore: Int
    let awayScore: Int
    var id: String { leagueId }

    /// Whether the picked team was the home team.
    var pickedHome: Bool { teamId == homeTeamId }
}
