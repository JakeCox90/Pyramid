import XCTest
@testable import Pyramid

@MainActor
final class PicksViewModelTests: XCTestCase {

    // MARK: - load()

    func testLoadSuccessSetsFixturesAndGameweek() async {
        let mock = MockPickService()
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)

        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.gameweek?.id, MockPickService.stubGameweek.id)
        XCTAssertEqual(vm.fixtures.count, 2)
        XCTAssertNil(vm.currentPick)
    }

    func testLoadSetsCurrentPickWhenExists() async {
        let mock = MockPickService(currentPick: MockPickService.stubPick)
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)

        await vm.load()

        XCTAssertEqual(vm.currentPick?.teamId, MockPickService.stubPick.teamId)
    }

    func testLoadSetsUsedTeamIds() async {
        let mock = MockPickService(usedTeamIds: [101, 202])
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)

        await vm.load()

        XCTAssertEqual(vm.usedTeamIds, [101, 202])
    }

    func testLoadFailureSetsErrorMessage() async {
        let mock = MockPickService(shouldFail: true)
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)

        await vm.load()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.fixtures.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testIsNotLoadingAfterLoad() async {
        let mock = MockPickService()
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)

        await vm.load()

        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - submitPick()

    func testSubmitPickSuccessSetsSuccessMessage() async {
        let mock = MockPickService()
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        await vm.submitPick(fixtureId: 1, teamId: 100, teamName: "Arsenal")

        XCTAssertNotNil(vm.successMessage)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isSubmitting)
    }

    func testSubmitPickFailureSetsErrorMessage() async {
        let mock = MockPickService(submitShouldFail: true)
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        await vm.submitPick(fixtureId: 1, teamId: 100, teamName: "Arsenal")

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.successMessage)
        XCTAssertFalse(vm.isSubmitting)
    }

    func testSubmitPickCallsServiceWithCorrectArgs() async {
        let mock = MockPickService()
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        await vm.submitPick(fixtureId: 999, teamId: 42, teamName: "Chelsea")

        XCTAssertTrue(mock.submitPickCalled)
        XCTAssertEqual(mock.lastSubmitFixtureId, 999)
        XCTAssertEqual(mock.lastSubmitTeamId, 42)
        XCTAssertEqual(mock.lastSubmitTeamName, "Chelsea")
        XCTAssertEqual(mock.lastSubmitLeagueId, "league-1")
    }

    func testIsNotSubmittingAfterSubmit() async {
        let mock = MockPickService()
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        await vm.submitPick(fixtureId: 1, teamId: 100, teamName: "Arsenal")

        XCTAssertFalse(vm.isSubmitting)
    }

    // MARK: - isTeamPicked

    func testIsTeamPickedReturnsTrueForCurrentPickTeam() async {
        let mock = MockPickService(currentPick: MockPickService.stubPick)
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        XCTAssertTrue(vm.isTeamPicked(MockPickService.stubPick.teamId))
    }

    func testIsTeamPickedReturnsFalseForOtherTeam() async {
        let mock = MockPickService(currentPick: MockPickService.stubPick)
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        XCTAssertFalse(vm.isTeamPicked(999))
    }

    func testIsTeamPickedReturnsFalseWithNoPick() async {
        let mock = MockPickService()
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        XCTAssertFalse(vm.isTeamPicked(100))
    }

    // MARK: - isTeamUsed

    func testUsedTeamIsDisabledWhenNotCurrentPick() async {
        let mock = MockPickService(usedTeamIds: [101])
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        XCTAssertTrue(vm.isTeamUsed(101))
    }

    func testCurrentPickTeamNotConsideredUsed() async {
        let pick = MockPickService.stubPick  // teamId = 100
        let mock = MockPickService(currentPick: pick, usedTeamIds: [100])
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        // Current pick's team should not be disabled even if in usedTeamIds
        XCTAssertFalse(vm.isTeamUsed(100))
    }

    func testUnusedTeamIsNotDisabled() async {
        let mock = MockPickService(usedTeamIds: [101])
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        XCTAssertFalse(vm.isTeamUsed(999))
    }

    // MARK: - deadlineText

    func testDeadlineTextNilWhenNoGameweek() {
        let vm = PicksViewModel(leagueId: "league-1", pickService: MockPickService())
        XCTAssertNil(vm.deadlineText)
    }

    func testDeadlineTextShowsPassedWhenDeadlineInPast() async {
        let pastDate = Date().addingTimeInterval(-3600)
        let gw = Gameweek(id: 1, season: 2025, roundNumber: 1, name: "Gameweek 1",
                          deadlineAt: pastDate, isCurrent: true, isFinished: false)
        let mock = MockPickService(gameweek: gw)
        let vm = PicksViewModel(leagueId: "league-1", pickService: mock)
        await vm.load()

        XCTAssertEqual(vm.deadlineText, "Deadline passed")
    }
}

// MARK: - Mock

final class MockPickService: PickServiceProtocol {

    static let stubGameweek = Gameweek(
        id: 29, season: 2025, roundNumber: 29, name: "Gameweek 29",
        deadlineAt: Date().addingTimeInterval(86400),
        isCurrent: true, isFinished: false
    )

    static let stubPick = Pick(
        id: "pick-uuid", leagueId: "league-1", userId: "user-1",
        gameweekId: 29, fixtureId: 1, teamId: 100, teamName: "Arsenal",
        isLocked: false, result: .pending, submittedAt: Date()
    )

    private let gameweek: Gameweek
    private let currentPick: Pick?
    private let usedTeamIds: Set<Int>
    private let shouldFail: Bool
    private let submitShouldFail: Bool

    var submitPickCalled = false
    var lastSubmitLeagueId: String?
    var lastSubmitFixtureId: Int?
    var lastSubmitTeamId: Int?
    var lastSubmitTeamName: String?

    init(
        gameweek: Gameweek = MockPickService.stubGameweek,
        currentPick: Pick? = nil,
        usedTeamIds: Set<Int> = [],
        shouldFail: Bool = false,
        submitShouldFail: Bool = false
    ) {
        self.gameweek = gameweek
        self.currentPick = currentPick
        self.usedTeamIds = usedTeamIds
        self.shouldFail = shouldFail
        self.submitShouldFail = submitShouldFail
    }

    func fetchCurrentGameweek() async throws -> Gameweek {
        if shouldFail { throw URLError(.badServerResponse) }
        return gameweek
    }

    func fetchFixtures(for gameweekId: Int) async throws -> [Fixture] {
        if shouldFail { throw URLError(.badServerResponse) }
        return [
            Fixture(id: 1, gameweekId: gameweekId,
                    homeTeamId: 100, homeTeamName: "Arsenal", homeTeamShort: "ARS",
                    awayTeamId: 200, awayTeamName: "Chelsea", awayTeamShort: "CHE",
                    kickoffAt: Date().addingTimeInterval(86400),
                    status: .notStarted, homeScore: nil, awayScore: nil),
            Fixture(id: 2, gameweekId: gameweekId,
                    homeTeamId: 300, homeTeamName: "Liverpool", homeTeamShort: "LIV",
                    awayTeamId: 400, awayTeamName: "Man City", awayTeamShort: "MCI",
                    kickoffAt: Date().addingTimeInterval(90000),
                    status: .notStarted, homeScore: nil, awayScore: nil)
        ]
    }

    func fetchMyPick(leagueId: String, gameweekId: Int) async throws -> Pick? {
        if shouldFail { throw URLError(.badServerResponse) }
        return currentPick
    }

    func fetchUsedTeamIds(leagueId: String) async throws -> Set<Int> {
        if shouldFail { throw URLError(.badServerResponse) }
        return usedTeamIds
    }

    func submitPick(
        leagueId: String,
        fixtureId: Int,
        teamId: Int,
        teamName: String
    ) async throws -> SubmitPickResponse {
        if submitShouldFail { throw URLError(.badServerResponse) }
        submitPickCalled = true
        lastSubmitLeagueId = leagueId
        lastSubmitFixtureId = fixtureId
        lastSubmitTeamId = teamId
        lastSubmitTeamName = teamName
        return SubmitPickResponse(pickId: "new-pick-id", teamName: teamName, fixtureId: fixtureId, isLocked: false)
    }
}
