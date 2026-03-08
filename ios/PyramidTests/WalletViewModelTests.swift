import XCTest
@testable import Pyramid

@MainActor
final class WalletViewModelTests: XCTestCase {

    // MARK: - Fixtures

    static let stubWallet = WalletBalance(
        availableToPlayPence: 5000,
        withdrawablePence: 2500,
        pendingPence: 0
    )

    static let stubTransactions: [WalletTransaction] = [
        WalletTransaction(
            id: "tx-1",
            type: .topUp,
            amountPence: 1000,
            createdAt: Date(),
            notes: nil,
            disputeWindowExpiresAt: nil
        ),
        WalletTransaction(
            id: "tx-2",
            type: .stake,
            amountPence: 500,
            createdAt: Date(),
            notes: "Gameweek 29",
            disputeWindowExpiresAt: nil
        )
    ]

    // MARK: - load()

    func testLoadSuccessSetsWalletAndTransactions() async {
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: Self.stubTransactions)
        let vm = WalletViewModel(service: mock)

        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNotNil(vm.wallet)
        XCTAssertEqual(vm.wallet?.availableToPlayPence, 5000)
        XCTAssertEqual(vm.transactions.count, 2)
    }

    func testLoadFailureSetsErrorMessage() async {
        let mock = MockWalletService(shouldFail: true)
        let vm = WalletViewModel(service: mock)

        await vm.load()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.wallet)
        XCTAssertTrue(vm.transactions.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testIsNotLoadingAfterLoad() async {
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: Self.stubTransactions)
        let vm = WalletViewModel(service: mock)

        await vm.load()

        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - requestWithdrawal(amountPence:)

    func testWithdrawalRejectsBelowMinimum() async {
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: [])
        let vm = WalletViewModel(service: mock)
        await vm.load()

        await vm.requestWithdrawal(amountPence: 1999)  // £19.99 — below £20 minimum

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(mock.withdrawalCalled)
    }

    func testWithdrawalRejectsAboveWithdrawableBalance() async {
        // Wallet has £25 withdrawable (2500p)
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: [])
        let vm = WalletViewModel(service: mock)
        await vm.load()

        await vm.requestWithdrawal(amountPence: 3000)  // £30 — exceeds withdrawable £25

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(mock.withdrawalCalled)
    }

    func testWithdrawalSucceedsWithValidAmount() async {
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: [])
        let vm = WalletViewModel(service: mock)
        await vm.load()

        await vm.requestWithdrawal(amountPence: 2000)  // £20 — exactly the minimum

        XCTAssertTrue(mock.withdrawalCalled)
        XCTAssertEqual(mock.lastWithdrawalAmountPence, 2000)
    }

    func testWithdrawalServiceErrorSetsErrorMessage() async {
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: [], withdrawalShouldFail: true)
        let vm = WalletViewModel(service: mock)
        await vm.load()

        await vm.requestWithdrawal(amountPence: 2000)

        XCTAssertNotNil(vm.errorMessage)
    }

    func testWithdrawalClosesSheetOnSuccess() async {
        let mock = MockWalletService(wallet: Self.stubWallet, transactions: [])
        let vm = WalletViewModel(service: mock)
        await vm.load()
        vm.showWithdrawSheet = true

        await vm.requestWithdrawal(amountPence: 2000)

        XCTAssertFalse(vm.showWithdrawSheet)
    }

    // MARK: - WalletBalance formatting

    func testWalletBalanceFormatsCorrectly() {
        let balance = WalletBalance(availableToPlayPence: 1050, withdrawablePence: 500, pendingPence: 0)
        XCTAssertEqual(balance.availableToPlayFormatted, "£10.50")
        XCTAssertEqual(balance.withdrawableFormatted, "£5.00")
    }

    // MARK: - WalletTransaction isCredit

    func testTopUpIsCredit() {
        let tx = WalletTransaction(id: "1", type: .topUp, amountPence: 1000, createdAt: Date(),
                                   notes: nil, disputeWindowExpiresAt: nil)
        XCTAssertTrue(tx.isCredit)
    }

    func testStakeRefundIsCredit() {
        let tx = WalletTransaction(id: "2", type: .stakeRefund, amountPence: 500, createdAt: Date(),
                                   notes: nil, disputeWindowExpiresAt: nil)
        XCTAssertTrue(tx.isCredit)
    }

    func testWinningsIsCredit() {
        let tx = WalletTransaction(id: "3", type: .winnings, amountPence: 2000, createdAt: Date(),
                                   notes: nil, disputeWindowExpiresAt: nil)
        XCTAssertTrue(tx.isCredit)
    }

    func testStakeIsDebit() {
        let tx = WalletTransaction(id: "4", type: .stake, amountPence: 500, createdAt: Date(),
                                   notes: nil, disputeWindowExpiresAt: nil)
        XCTAssertFalse(tx.isCredit)
    }

    func testWithdrawalIsDebit() {
        let tx = WalletTransaction(id: "5", type: .withdrawal, amountPence: 2000, createdAt: Date(),
                                   notes: nil, disputeWindowExpiresAt: nil)
        XCTAssertFalse(tx.isCredit)
    }
}

// MARK: - Mock

final class MockWalletService: WalletServiceProtocol {
    private let wallet: WalletBalance?
    private let transactions: [WalletTransaction]
    private let shouldFail: Bool
    private let withdrawalShouldFail: Bool

    var withdrawalCalled = false
    var lastWithdrawalAmountPence: Int?

    init(
        wallet: WalletBalance? = nil,
        transactions: [WalletTransaction] = [],
        shouldFail: Bool = false,
        withdrawalShouldFail: Bool = false
    ) {
        self.wallet = wallet
        self.transactions = transactions
        self.shouldFail = shouldFail
        self.withdrawalShouldFail = withdrawalShouldFail
    }

    func fetchWallet() async throws -> WalletBalance {
        if shouldFail { throw URLError(.badServerResponse) }
        return wallet ?? WalletBalance(availableToPlayPence: 0, withdrawablePence: 0, pendingPence: 0)
    }

    func fetchTransactions() async throws -> [WalletTransaction] {
        if shouldFail { throw URLError(.badServerResponse) }
        return transactions
    }

    func requestWithdrawal(amountPence: Int) async throws {
        if withdrawalShouldFail { throw URLError(.badServerResponse) }
        withdrawalCalled = true
        lastWithdrawalAmountPence = amountPence
    }

    func topUp(amountPence: Int, paymentIntentId: String) async throws {
        // Not tested at this layer — Stripe integration is PYR-25 GATE
    }
}
