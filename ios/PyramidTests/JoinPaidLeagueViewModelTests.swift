import XCTest
@testable import Pyramid

// MARK: - Mock

final class MockPaidLeagueService: PaidLeagueServiceProtocol {
    var joinCalled = false
    var fetchWalletCalled = false

    var walletBalanceToReturn: Int
    var joinResultToReturn: JoinPaidLeagueResponse
    var shouldFailJoin: Bool
    var shouldFailWallet: Bool
    var joinError: Error

    init(
        walletBalance: Int = 1000,
        shouldFailJoin: Bool = false,
        shouldFailWallet: Bool = false,
        joinError: Error = URLError(.badServerResponse)
    ) {
        self.walletBalanceToReturn = walletBalance
        self.shouldFailJoin = shouldFailJoin
        self.shouldFailWallet = shouldFailWallet
        self.joinError = joinError
        self.joinResultToReturn = JoinPaidLeagueResponse(
            leagueId: "test-league-id",
            pseudonym: "Player 1",
            status: .waiting,
            playerCount: 1
        )
    }

    func fetchWalletBalance() async throws -> Int {
        fetchWalletCalled = true
        if shouldFailWallet { throw URLError(.badServerResponse) }
        return walletBalanceToReturn
    }

    func joinPaidLeague() async throws -> JoinPaidLeagueResponse {
        joinCalled = true
        if shouldFailJoin { throw joinError }
        return joinResultToReturn
    }
}

// MARK: - Tests

@MainActor
final class JoinPaidLeagueViewModelTests: XCTestCase {

    // MARK: - load()

    func testLoadFetchesWalletBalance() async {
        let mock = MockPaidLeagueService(walletBalance: 1500)
        let vm = JoinPaidLeagueViewModel(service: mock)

        await vm.load()

        XCTAssertTrue(mock.fetchWalletCalled)
        XCTAssertEqual(vm.walletBalance, 1500)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadSetsHasInsufficientFundsWhenBalanceLow() async {
        let mock = MockPaidLeagueService(walletBalance: 300) // < 500p
        let vm = JoinPaidLeagueViewModel(service: mock)

        await vm.load()

        XCTAssertTrue(vm.hasInsufficientFunds)
    }

    func testLoadClearsInsufficientFundsWhenBalanceSufficient() async {
        let mock = MockPaidLeagueService(walletBalance: 500)
        let vm = JoinPaidLeagueViewModel(service: mock)

        await vm.load()

        XCTAssertFalse(vm.hasInsufficientFunds)
    }

    func testLoadSetsErrorMessageOnFailure() async {
        let mock = MockPaidLeagueService(shouldFailWallet: true)
        let vm = JoinPaidLeagueViewModel(service: mock)

        await vm.load()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - joinLeague()

    func testJoinLeagueCallsServiceAndSetsResult() async {
        let mock = MockPaidLeagueService(walletBalance: 1000)
        let vm = JoinPaidLeagueViewModel(service: mock)
        await vm.load()

        await vm.joinLeague()

        XCTAssertTrue(mock.joinCalled)
        XCTAssertNotNil(vm.joinResult)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testJoinLeagueWithInsufficientFundsSetsErrorWithoutCallingService() async {
        let mock = MockPaidLeagueService(walletBalance: 100) // < 500p
        let vm = JoinPaidLeagueViewModel(service: mock)
        await vm.load()

        await vm.joinLeague()

        XCTAssertFalse(mock.joinCalled)
        XCTAssertNil(vm.joinResult)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testJoinLeagueServiceFailureSetsErrorMessage() async {
        let mock = MockPaidLeagueService(walletBalance: 1000, shouldFailJoin: true)
        let vm = JoinPaidLeagueViewModel(service: mock)
        await vm.load()

        await vm.joinLeague()

        XCTAssertNil(vm.joinResult)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testJoinLeagueWith409CapReachedSetsAppropriateError() async {
        let capError = PaidLeagueServiceError.leagueCapReached
        let mock = MockPaidLeagueService(walletBalance: 1000, shouldFailJoin: true, joinError: capError)
        let vm = JoinPaidLeagueViewModel(service: mock)
        await vm.load()

        await vm.joinLeague()

        XCTAssertNil(vm.joinResult)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.errorMessage, capError.localizedDescription)
    }

    // MARK: - Computed properties

    func testEstimatedPrizePotFormat() {
        let mock = MockPaidLeagueService()
        let vm = JoinPaidLeagueViewModel(service: mock)
        // 30 * 500 * 0.92 = 13800p = £138 → "up to £138"
        XCTAssertEqual(vm.estimatedPrizePot, "up to £138")
    }

    func testWalletBalanceFormattedShowsPounds() async {
        let mock = MockPaidLeagueService(walletBalance: 1050)
        let vm = JoinPaidLeagueViewModel(service: mock)
        await vm.load()

        XCTAssertEqual(vm.walletBalanceFormatted, "£10.50")
    }
}
