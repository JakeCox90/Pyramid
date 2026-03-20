import SwiftUI

// MARK: - Transaction History

extension WalletView {
    var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transaction History")
                .font(.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .padding(.horizontal, 16)

            if viewModel.transactions.isEmpty {
                emptyTransactionsView
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != viewModel.transactions.last?.id {
                            Divider()
                                .overlay(Theme.Color.Border.default)
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Theme.Color.Surface.Background.container)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
        }
    }

    var emptyTransactionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: Theme.Icon.Wallet.empty)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .accessibilityHidden(true)
            Text("No transactions yet")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}
