import SwiftUI

// MARK: - WalletView

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.Surface.Background.page.ignoresSafeArea()

                if viewModel.isLoading && viewModel.wallet == nil {
                    ProgressView()
                        .tint(Theme.Color.Content.Text.default)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            balanceHeader
                            transactionHistorySection
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $viewModel.showTopUpSheet) {
            TopUpSheet(isPresented: $viewModel.showTopUpSheet)
        }
        .sheet(isPresented: $viewModel.showWithdrawSheet) {
            WithdrawSheet(
                isPresented: $viewModel.showWithdrawSheet,
                withdrawablePence: viewModel.wallet?.withdrawablePence ?? 0,
                withdrawableFormatted: viewModel.wallet?.withdrawableFormatted ?? "£0.00",
                onWithdraw: { amount in
                    await viewModel.requestWithdrawal(amountPence: amount)
                }
            )
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Balance Header

    private var balanceHeader: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Available to Play")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                Text(viewModel.wallet?.availableToPlayFormatted ?? "–")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("Withdrawable")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                    Text(viewModel.wallet?.withdrawableFormatted ?? "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            withdrawable > 0
                                ? Theme.Color.Status.Success.resting
                                : Theme.Color.Content.Text.subtle
                        )
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Theme.Color.Border.default)
                    .frame(width: 1, height: 32)

                VStack(spacing: 2) {
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    Text(viewModel.wallet?.pendingFormatted ?? "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button {
                    viewModel.showTopUpSheet = true
                } label: {
                    Text("Top Up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Color.Primary.resting)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                Button {
                    viewModel.showWithdrawSheet = true
                } label: {
                    Text("Withdraw")
                        .font(.headline)
                        .foregroundStyle(
                            withdrawable > 0
                                ? Theme.Color.Content.Text.default
                                : Theme.Color.Content.Text.disabled
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Color.Surface.Background.container)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(withdrawable == 0)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Transaction History

    private var transactionHistorySection: some View {
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

    private var emptyTransactionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: Theme.Icon.Wallet.empty)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.Content.Text.disabled)
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

// MARK: - Transaction Row

private struct TransactionRow: View {
    let transaction: WalletTransaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconBackgroundColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transactionTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Color.Content.Text.default)
                if let notes = transaction.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                } else {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }
            }

            Spacer()

            Text((transaction.isCredit ? "+" : "-") + transaction.amountFormatted)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    transaction.isCredit
                        ? Theme.Color.Status.Success.resting
                        : Theme.Color.Status.Error.resting
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var iconName: String {
        switch transaction.type {
        case .topUp:
            return Theme.Icon.Wallet.topUp
        case .stake:
            return Theme.Icon.League.trophyCircle
        case .stakeRefund:
            return Theme.Icon.Wallet.refund
        case .winnings:
            return Theme.Icon.Wallet.winnings
        case .withdrawal:
            return Theme.Icon.Wallet.withdrawal
        }
    }

    private var iconBackgroundColor: Color {
        switch transaction.type {
        case .topUp, .winnings:
            return Theme.Color.Status.Success.resting
        case .stake:
            return Theme.Color.Primary.resting
        case .stakeRefund:
            return Theme.Color.Status.Warning.resting
        case .withdrawal:
            return Theme.Color.Status.Error.resting
        }
    }

    private var transactionTitle: String {
        switch transaction.type {
        case .topUp:
            return "Top Up"
        case .stake:
            return "Stake"
        case .stakeRefund:
            return "Stake Refund"
        case .winnings:
            return "Winnings"
        case .withdrawal:
            return "Withdrawal"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: transaction.createdAt)
    }
}
