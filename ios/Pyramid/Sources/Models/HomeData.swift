import Foundation

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
}

/// A user's pick paired with its fixture and league name for homepage display.
struct LivePickContext: Identifiable, Equatable {
    let pick: Pick
    let fixture: Fixture
    let leagueName: String
    var id: String { pick.id }

    var isSurviving: Bool? {
        guard fixture.status.isLive || fixture.status.isFinished else {
            return nil
        }
        let homeScore = fixture.homeScore ?? 0
        let awayScore = fixture.awayScore ?? 0
        if pick.teamId == fixture.homeTeamId {
            return homeScore >= awayScore
        } else {
            return awayScore >= homeScore
        }
    }
}

/// A single league result from the previous settled gameweek.
struct LeagueResult: Identifiable, Sendable, Equatable {
    let leagueId: String
    let leagueName: String
    let gameweekName: String
    let teamName: String
    let result: PickResult
    let homeTeamName: String
    let homeTeamShort: String
    let homeTeamLogo: String?
    let awayTeamName: String
    let awayTeamShort: String
    let awayTeamLogo: String?
    let homeScore: Int
    let awayScore: Int
    var id: String { leagueId }
}
