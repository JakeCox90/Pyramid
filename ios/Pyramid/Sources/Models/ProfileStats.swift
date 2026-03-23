import Foundation

// MARK: - ProfileStats

struct ProfileStats: Equatable {
    let totalLeaguesJoined: Int
    let wins: Int
    let totalPicksMade: Int
    let longestSurvivalStreak: Int
    let survivalRatePct: Int
    let activeStreaks: [LeagueStreak]
    let leagueHistory: [CompletedLeague]

    static let empty = ProfileStats(
        totalLeaguesJoined: 0,
        wins: 0,
        totalPicksMade: 0,
        longestSurvivalStreak: 0,
        survivalRatePct: 0,
        activeStreaks: [],
        leagueHistory: []
    )
}

// MARK: - LeagueStreak

struct LeagueStreak: Identifiable, Equatable {
    let id: String
    let leagueName: String
    let currentStreak: Int
}

// MARK: - CompletedLeague

struct CompletedLeague: Identifiable, Equatable {
    let id: String
    let leagueName: String
    let result: CompletedLeagueResult
    let eliminatedGameweek: Int?
    let season: Int
}

// MARK: - CompletedLeagueResult

enum CompletedLeagueResult: Equatable {
    case winner
    case eliminated
}
