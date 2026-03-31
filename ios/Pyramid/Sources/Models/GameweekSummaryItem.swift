import Foundation

/// One league's settled result for the Gameweek Summary overlay and homepage result card.
struct GameweekSummaryItem: Identifiable, Equatable {
    let leagueId: String
    let leagueName: String
    let result: SummaryResult
    let pickedTeamName: String
    let opponentName: String
    let homeTeamName: String
    let homeTeamShort: String
    let homeTeamLogo: String?
    let awayTeamName: String
    let awayTeamShort: String
    let awayTeamLogo: String?
    let homeScore: Int
    let awayScore: Int
    let pickedHome: Bool
    let survivalStreak: Int
    let playersRemaining: Int
    let totalPlayers: Int

    var id: String { leagueId }

    enum SummaryResult: Equatable {
        case survived
        case eliminated
    }

    /// The picked team's logo URL.
    var pickedTeamLogo: String? {
        pickedHome ? homeTeamLogo : awayTeamLogo
    }
}
