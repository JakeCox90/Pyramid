import XCTest
@testable import Pyramid

@MainActor
final class ResultsViewModelTests: XCTestCase {

    // MARK: - Test Data

    static let finishedGameweeks: [Gameweek] = [
        Gameweek(
            id: 5, season: 2025, roundNumber: 5,
            name: "Gameweek 5", deadlineAt: Date().addingTimeInterval(-86400),
            isCurrent: false, isFinished: true
        ),
        Gameweek(
            id: 4, season: 2025, roundNumber: 4,
            name: "Gameweek 4", deadlineAt: Date().addingTimeInterval(-172800),
            isCurrent: false, isFinished: true
        )
    ]

    static let settledPicks: [RoundPickRow] = [
        RoundPickRow(
            userId: "u1", teamName: "Arsenal", result: .survived,
            gameweekId: 5, fixtureId: 101,
            profiles: .init(username: "alice", displayName: "Alice")
        ),
        RoundPickRow(
            userId: "u2", teamName: "Chelsea", result: .eliminated,
            gameweekId: 5, fixtureId: 102,
            profiles: .init(username: "bob", displayName: "Bob")
        ),
        RoundPickRow(
            userId: "u1", teamName: "Liverpool", result: .survived,
            gameweekId: 4, fixtureId: 201,
            profiles: .init(username: "alice", displayName: "Alice")
        ),
        RoundPickRow(
            userId: "u2", teamName: "Man City", result: .survived,
            gameweekId: 4, fixtureId: 202,
            profiles: .init(username: "bob", displayName: "Bob")
        )
    ]

    static let fixtures: [Fixture] = [
        Fixture(
            id: 101, gameweekId: 5,
            homeTeamId: 100, homeTeamName: "Arsenal", homeTeamShort: "ARS",
            homeTeamLogo: nil,
            awayTeamId: 200, awayTeamName: "Spurs", awayTeamShort: "TOT",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-86400),
            status: .fullTime, homeScore: 2, awayScore: 0
        ),
        Fixture(
            id: 102, gameweekId: 5,
            homeTeamId: 300, homeTeamName: "Chelsea", homeTeamShort: "CHE",
            homeTeamLogo: nil,
            awayTeamId: 400, awayTeamName: "Liverpool", awayTeamShort: "LIV",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-86400),
            status: .fullTime, homeScore: 0, awayScore: 1
        ),
        Fixture(
            id: 201, gameweekId: 4,
            homeTeamId: 500, homeTeamName: "Liverpool", homeTeamShort: "LIV",
            homeTeamLogo: nil,
            awayTeamId: 600, awayTeamName: "Man Utd", awayTeamShort: "MUN",
            awayTeamLogo: nil,
            kickoffAt: Date().addingTimeInterval(-172800),
            status: .fullTime, homeScore: 3, awayScore: 1
        )
    ]

    // MARK: - load()

    func testLoadSuccessSetsRounds() async {
        let mock = MockResultsService(
            gameweeks: Self.finishedGameweeks,
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.rounds.count, 2)
    }

    func testRoundsGroupedByGameweek() async {
        let mock = MockResultsService(
            gameweeks: Self.finishedGameweeks,
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        let gw5 = vm.rounds.first { $0.gameweek.id == 5 }
        XCTAssertEqual(gw5?.picks.count, 2)
        let gw4 = vm.rounds.first { $0.gameweek.id == 4 }
        XCTAssertEqual(gw4?.picks.count, 2)
    }

    func testLoadFailureSetsError() async {
        let mock = MockResultsService(shouldFail: true)
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.rounds.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testEmptyGameweeksReturnsEmptyRounds() async {
        let mock = MockResultsService(
            gameweeks: [],
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        XCTAssertTrue(vm.rounds.isEmpty)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - RoundResult counts

    func testSurvivedAndEliminatedCounts() async {
        let mock = MockResultsService(
            gameweeks: Self.finishedGameweeks,
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        let gw5 = vm.rounds.first { $0.gameweek.id == 5 }
        XCTAssertEqual(gw5?.survivedCount, 1)
        XCTAssertEqual(gw5?.eliminatedCount, 1)
        XCTAssertEqual(gw5?.voidCount, 0)
    }

    // MARK: - toggleRound

    func testToggleRoundExpandsAndCollapses() {
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: MockResultsService()
        )

        XCTAssertNil(vm.expandedRoundId)

        vm.toggleRound(5)
        XCTAssertEqual(vm.expandedRoundId, 5)

        vm.toggleRound(5)
        XCTAssertNil(vm.expandedRoundId)
    }

    func testToggleDifferentRoundSwitches() {
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: MockResultsService()
        )

        vm.toggleRound(5)
        XCTAssertEqual(vm.expandedRoundId, 5)

        vm.toggleRound(4)
        XCTAssertEqual(vm.expandedRoundId, 4)
    }

    // MARK: - RoundResult.fixture(for:)

    func testFixtureLookup() async {
        let mock = MockResultsService(
            gameweeks: Self.finishedGameweeks,
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        let gw5 = vm.rounds.first { $0.gameweek.id == 5 }
        let fixture = gw5?.fixture(for: 101)
        XCTAssertNotNil(fixture)
        XCTAssertEqual(fixture?.homeTeamShort, "ARS")
    }

    func testPicksSortedEliminatedFirst() async {
        let mock = MockResultsService(
            gameweeks: Self.finishedGameweeks,
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        let gw5 = vm.rounds.first { $0.gameweek.id == 5 }
        XCTAssertEqual(gw5?.picks.first?.result, .eliminated)
        XCTAssertEqual(gw5?.picks.last?.result, .survived)
    }

    // MARK: - Gameweeks without picks are excluded

    func testGameweekWithNoPicksExcluded() async {
        let extraGw = Gameweek(
            id: 3, season: 2025, roundNumber: 3,
            name: "Gameweek 3",
            deadlineAt: Date().addingTimeInterval(-259200),
            isCurrent: false, isFinished: true
        )
        let mock = MockResultsService(
            gameweeks: Self.finishedGameweeks + [extraGw],
            picks: Self.settledPicks,
            fixtures: Self.fixtures
        )
        let vm = ResultsViewModel(
            leagueId: "league-1", season: 2025,
            resultsService: mock
        )

        await vm.load()

        XCTAssertEqual(vm.rounds.count, 2)
        XCTAssertNil(vm.rounds.first { $0.gameweek.id == 3 })
    }
}

// MARK: - Mock

final class MockResultsService: ResultsServiceProtocol {
    private let gameweeks: [Gameweek]
    private let picks: [RoundPickRow]
    private let fixtures: [Fixture]
    private let shouldFail: Bool

    init(
        gameweeks: [Gameweek] = [],
        picks: [RoundPickRow] = [],
        fixtures: [Fixture] = [],
        shouldFail: Bool = false
    ) {
        self.gameweeks = gameweeks
        self.picks = picks
        self.fixtures = fixtures
        self.shouldFail = shouldFail
    }

    func fetchFinishedGameweeks(season: Int) async throws -> [Gameweek] {
        if shouldFail { throw URLError(.badServerResponse) }
        return gameweeks
    }

    func fetchSettledPicks(leagueId: String) async throws -> [RoundPickRow] {
        if shouldFail { throw URLError(.badServerResponse) }
        return picks
    }

    func fetchFixtures(gameweekIds: [Int]) async throws -> [Fixture] {
        if shouldFail { throw URLError(.badServerResponse) }
        return fixtures
    }
}
