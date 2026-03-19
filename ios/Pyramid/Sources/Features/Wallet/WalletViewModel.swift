import SwiftUI

// MARK: - Validation Constants

private let withdrawalMinimumPence = 2000  // £20.00

// MARK: - ViewModel

@MainActor
final class WalletViewModel: ObservableObject {
    @Published var wallet: WalletBalance?
    @Published var transactions: [WalletTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showTopUpSheet = false
    @Published var showWithdrawSheet = false

    private let service: WalletServiceProtocol

    init(service: WalletServiceProtocol = WalletService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let walletFetch = service.fetchWallet()
            async let txFetch = service.fetchTransactions()
            let (fetchedWallet, fetchedTx) = try await (walletFetch, txFetch)
            wallet = fetchedWallet
            transactions = fetchedTx
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func requestWithdrawal(amountPence: Int) async {
        guard amountPence >= withdrawalMinimumPence else {
            errorMessage = "Minimum withdrawal is £20.00."
            return
        }
        guard let withdrawable = wallet?.withdrawablePence, amountPence <= withdrawable else {
            errorMessage = "Amount exceeds your withdrawable balance."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await service.requestWithdrawal(amountPence: amountPence)
            showWithdrawSheet = false
            await load()
        } catch {
            errorMessage = AppError.from(error).userMessage
            isLoading = false
        }
    }
}
