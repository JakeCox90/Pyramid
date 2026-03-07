import XCTest
@testable import Pyramid

@MainActor
final class JoinLeagueViewModelTests: XCTestCase {

    // MARK: - Code Validation

    func testEmptyCodeIsInvalid() {
        let vm = JoinLeagueViewModel(leagueService: MockLeagueService())
        vm.code = ""
        XCTAssertFalse(vm.isCodeValid)
    }

    func testFiveCharCodeIsInvalid() {
        let vm = JoinLeagueViewModel(leagueService: MockLeagueService())
        vm.code = "ABCDE"
        XCTAssertFalse(vm.isCodeValid)
    }

    func testSixCharCodeIsValid() {
        let vm = JoinLeagueViewModel(leagueService: MockLeagueService())
        vm.code = "ABC123"
        XCTAssertTrue(vm.isCodeValid)
    }

    func testSevenCharCodeIsInvalid() {
        let vm = JoinLeagueViewModel(leagueService: MockLeagueService())
        vm.code = "ABCDEFG"
        XCTAssertFalse(vm.isCodeValid)
    }

    func testNormalizedCodeIsUppercased() {
        let vm = JoinLeagueViewModel(leagueService: MockLeagueService())
        vm.code = "abc123"
        XCTAssertEqual(vm.normalizedCode, "ABC123")
    }

    // MARK: - Lookup

    func testLookupWithShortCodeSetsError() async {
        let vm = JoinLeagueViewModel(leagueService: MockLeagueService())
        vm.code = "AB"

        await vm.lookupCode()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        if case .enterCode = vm.step {} else {
            XCTFail("Expected enterCode step")
        }
    }

    func testLookupWithValidCodeCallsServiceAndShowsPreview() async {
        let mock = MockLeagueService()
        let vm = JoinLeagueViewModel(leagueService: mock)
        vm.code = "ABC123"

        await vm.lookupCode()

        XCTAssertTrue(mock.previewLeagueCalled)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        if case .preview = vm.step {} else {
            XCTFail("Expected preview step")
        }
    }

    func testLookupFailureSetsErrorAndStaysOnEnterCode() async {
        let mock = MockLeagueService(shouldFail: true)
        let vm = JoinLeagueViewModel(leagueService: mock)
        vm.code = "ABC123"

        await vm.lookupCode()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        if case .enterCode = vm.step {} else {
            XCTFail("Expected to remain on enterCode step")
        }
    }

    // MARK: - Confirm Join

    func testConfirmJoinCallsServiceAndAdvancesToJoined() async {
        let mock = MockLeagueService()
        let vm = JoinLeagueViewModel(leagueService: mock)
        vm.code = "ABC123"

        await vm.lookupCode() // moves to preview
        await vm.confirmJoin()

        XCTAssertTrue(mock.joinLeagueCalled)
        XCTAssertEqual(mock.lastJoinedCode, "ABC123")
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        if case .joined = vm.step {} else {
            XCTFail("Expected joined step")
        }
    }

    func testConfirmJoinFailureSetsError() async {
        let mockPreview = MockLeagueService()
        let vm = JoinLeagueViewModel(leagueService: mockPreview)
        vm.code = "ABC123"
        await vm.lookupCode() // preview succeeds

        // Swap to failing service (simulate server error on join)
        let failVM = JoinLeagueViewModel(leagueService: MockLeagueService(shouldFail: true))
        failVM.code = "ABC123"
        failVM.step = .preview(
            LeaguePreview(leagueId: "id", name: "Test", memberCount: 1, status: "pending", season: 2025)
        )

        await failVM.confirmJoin()

        XCTAssertNotNil(failVM.errorMessage)
        XCTAssertFalse(failVM.isLoading)
    }

    // MARK: - Reset

    func testResetToEnterCodeResetsState() async {
        let mock = MockLeagueService()
        let vm = JoinLeagueViewModel(leagueService: mock)
        vm.code = "ABC123"
        await vm.lookupCode()

        vm.resetToEnterCode()

        if case .enterCode = vm.step {} else {
            XCTFail("Expected enterCode step after reset")
        }
        XCTAssertNil(vm.errorMessage)
    }
}
