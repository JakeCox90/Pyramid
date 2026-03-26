import Foundation
@testable import Pyramid

// MARK: - Fixture Stubs

enum SnapshotStubs {
    static var tomorrow: Date {
        Calendar.current.date(
            bySettingHour: 15,
            minute: 0,
            second: 0,
            of: Date().addingTimeInterval(86400)
        ) ?? Date().addingTimeInterval(86400)
    }

    static var arsenalVsVilla: Fixture {
        Fixture(
            id: 99,
            gameweekId: 20,
            homeTeamId: 42,
            homeTeamName: "Arsenal",
            homeTeamShort: "ARS",
            homeTeamLogo: nil,
            awayTeamId: 66,
            awayTeamName: "Aston Villa",
            awayTeamShort: "AVL",
            awayTeamLogo: nil,
            kickoffAt: tomorrow,
            status: .notStarted,
            homeScore: nil,
            awayScore: nil,
            venue: "Emirates Stadium",
            homeWinProb: 0.55,
            drawProb: 0.25,
            awayWinProb: 0.20
        )
    }

    static var liveFixture: Fixture {
        Fixture(
            id: 100,
            gameweekId: 20,
            homeTeamId: 40,
            homeTeamName: "Liverpool",
            homeTeamShort: "LIV",
            homeTeamLogo: nil,
            awayTeamId: 49,
            awayTeamName: "Chelsea",
            awayTeamShort: "CHE",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-3600),
            status: .secondHalf,
            homeScore: 2,
            awayScore: 1,
            venue: "Anfield",
            homeWinProb: 0.60,
            drawProb: 0.20,
            awayWinProb: 0.20
        )
    }

    static var liveFixtureDrawing: Fixture {
        Fixture(
            id: 101,
            gameweekId: 20,
            homeTeamId: 40,
            homeTeamName: "Liverpool",
            homeTeamShort: "LIV",
            homeTeamLogo: nil,
            awayTeamId: 49,
            awayTeamName: "Chelsea",
            awayTeamShort: "CHE",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-3600),
            status: .secondHalf,
            homeScore: 0,
            awayScore: 0,
            venue: "Anfield",
            homeWinProb: 0.60,
            drawProb: 0.20,
            awayWinProb: 0.20
        )
    }

    static var finishedFixtureHomeWin: Fixture {
        Fixture(
            id: 102,
            gameweekId: 20,
            homeTeamId: 50,
            homeTeamName: "Man City",
            homeTeamShort: "MCI",
            homeTeamLogo: nil,
            awayTeamId: 47,
            awayTeamName: "Tottenham",
            awayTeamShort: "TOT",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-7200),
            status: .fullTime,
            homeScore: 3,
            awayScore: 0,
            venue: "Etihad Stadium",
            homeWinProb: 0.45,
            drawProb: 0.25,
            awayWinProb: 0.30
        )
    }

    static var finishedFixtureAwayWin: Fixture {
        Fixture(
            id: 103,
            gameweekId: 20,
            homeTeamId: 50,
            homeTeamName: "Man City",
            homeTeamShort: "MCI",
            homeTeamLogo: nil,
            awayTeamId: 47,
            awayTeamName: "Tottenham",
            awayTeamShort: "TOT",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-7200),
            status: .fullTime,
            homeScore: 1,
            awayScore: 2,
            venue: "Etihad Stadium",
            homeWinProb: 0.45,
            drawProb: 0.25,
            awayWinProb: 0.30
        )
    }
}
