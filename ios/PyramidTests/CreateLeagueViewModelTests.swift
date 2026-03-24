import XCTest
@testable import Pyramid

@MainActor
final class CreateLeagueViewModelTests: XCTestCase {

    // MARK: - Name Validation

    func testEmptyNameIsInvalid() {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = ""
        XCTAssertFalse(vm.isNameValid)
    }

    func testTwoCharNameIsInvalid() {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = "AB"
        XCTAssertFalse(vm.isNameValid)
    }

    func testThreeCharNameIsValid() {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = "ABC"
        XCTAssertTrue(vm.isNameValid)
    }

    func testFortyCharNameIsValid() {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = String(repeating: "A", count: 40)
        XCTAssertTrue(vm.isNameValid)
    }

    func testFortyOneCharNameIsInvalid() {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = String(repeating: "A", count: 41)
        XCTAssertFalse(vm.isNameValid)
    }

    func testWhitespaceOnlyNameIsInvalid() {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = "   "
        XCTAssertFalse(vm.isNameValid)
    }

    // MARK: - Submit

    func testSubmitWithShortNameSetsError() async {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = "AB"

        await vm.submit()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.createdLeague)
        XCTAssertFalse(vm.isLoading)
    }

    func testSubmitWithValidNameCallsService() async {
        let mock = MockLeagueService()
        let vm = CreateLeagueViewModel(leagueService: mock)
        vm.leagueName = "Sunday Heroes"

        await vm.submit()

        XCTAssertTrue(mock.createLeagueCalled)
        XCTAssertEqual(mock.lastCreatedName, "Sunday Heroes")
        XCTAssertNil(vm.errorMessage)
        XCTAssertNotNil(vm.createdLeague)
        XCTAssertFalse(vm.isLoading)
    }

    func testSubmitTrimsWhitespaceFromName() async {
        let mock = MockLeagueService()
        let vm = CreateLeagueViewModel(leagueService: mock)
        vm.leagueName = "  Sunday Heroes  "

        await vm.submit()

        XCTAssertEqual(mock.lastCreatedName, "Sunday Heroes")
    }

    func testSubmitFailureSetsErrorMessage() async {
        let mock = MockLeagueService(shouldFail: true)
        let vm = CreateLeagueViewModel(leagueService: mock)
        vm.leagueName = "Sunday Heroes"

        await vm.submit()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.createdLeague)
        XCTAssertFalse(vm.isLoading)
    }

    func testIsNotLoadingAfterSuccess() async {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService())
        vm.leagueName = "Test League"

        await vm.submit()

        XCTAssertFalse(vm.isLoading)
    }

    func testIsNotLoadingAfterFailure() async {
        let vm = CreateLeagueViewModel(leagueService: MockLeagueService(shouldFail: true))
        vm.leagueName = "Test League"

        await vm.submit()

        XCTAssertFalse(vm.isLoading)
    }
}

// MARK: - Mocks

final class MockLeagueService: LeagueServiceProtocol {
    var createLeagueCalled = false
    var lastCreatedName: String?
    var previewLeagueCalled = false
    var joinLeagueCalled = false
    var lastJoinedCode: String?
    var shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func createLeague(name: String) async throws -> CreateLeagueResponse {
        createLeagueCalled = true
        lastCreatedName = name
        if shouldFail { throw URLError(.badServerResponse) }
        return CreateLeagueResponse(leagueId: "test-id", joinCode: "ABC123", name: name)
    }

    func previewLeague(code: String) async throws -> LeaguePreview {
        previewLeagueCalled = true
        if shouldFail { throw URLError(.badServerResponse) }
        return LeaguePreview(leagueId: "test-id", name: "Test League", memberCount: 3, status: "pending", season: 2025)
    }

    func joinLeague(code: String) async throws -> JoinLeagueResponse {
        joinLeagueCalled = true
        lastJoinedCode = code
        if shouldFail { throw URLError(.badServerResponse) }
        return JoinLeagueResponse(leagueId: "test-id", name: "Test League")
    }

    func fetchMyLeagues() async throws -> [League] {
        if shouldFail { throw URLError(.badServerResponse) }
        return []
    }

    func fetchOpenLeagues() async throws -> [BrowseLeague] {
        if shouldFail { throw URLError(.badServerResponse) }
        return []
    }

    func updateLeague(
        leagueId: String,
        name: String,
        description: String?,
        colorPalette: String,
        emoji: String
    ) async throws {
        if shouldFail { throw URLError(.badServerResponse) }
    }
}
