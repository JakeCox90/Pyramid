import SwiftUI

// MARK: - WalletView

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.DS.Background.primary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.wallet == nil {
                    ProgressView()
                        .tint(Color.DS.Text.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: DS.Spacing.s4) {
                            balanceHeader
                            transactionHistorySection
                        }
                        .padding(.vertical, DS.Spacing.s4)
                    }
                }
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
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
        VStack(spacing: DS.Spacing.s3) {
            VStack(spacing: DS.Spacing.s1) {
                Text("Available to Play")
                    .font(.subheadline)
                    .foregroundStyle(Color.DS.Text.secondary)
                Text(viewModel.wallet?.availableToPlayFormatted ?? "–")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.DS.Text.primary)
            }

            HStack(spacing: DS.Spacing.s2) {
                VStack(spacing: 2) {
                    Text("Withdrawable")
                        .font(.caption)
                        .foregroundStyle(Color.DS.Text.tertiary)
                    let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                    Text(viewModel.wallet?.withdrawableFormatted ?? "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            withdrawable > 0
                                ? Color.DS.Semantic.success
                                : Color.DS.Text.secondary
                        )
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.DS.separator)
                    .frame(width: 1, height: 32)

                VStack(spacing: 2) {
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(Color.DS.Text.tertiary)
                    Text(viewModel.wallet?.pendingFormatted ?? "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.DS.Text.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, DS.Spacing.s3)
            .padding(.horizontal, DS.Spacing.s5)
            .background(Color.DS.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))

            HStack(spacing: DS.Spacing.s3) {
                Button {
                    viewModel.showTopUpSheet = true
                } label: {
                    Text("Top Up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.DS.Brand.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                }

                let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                Button {
                    viewModel.showWithdrawSheet = true
                } label: {
                    Text("Withdraw")
                        .font(.headline)
                        .foregroundStyle(
                            withdrawable > 0
                                ? Color.DS.Text.primary
                                : Color.DS.Text.tertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.DS.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                }
                .disabled(withdrawable == 0)
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    // MARK: - Transaction History

    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("Transaction History")
                .font(.headline)
                .foregroundStyle(Color.DS.Text.primary)
                .padding(.horizontal, DS.Spacing.pageMargin)

            if viewModel.transactions.isEmpty {
                emptyTransactionsView
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != viewModel.transactions.last?.id {
                            Divider()
                                .overlay(Color.DS.separator)
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color.DS.Background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                .padding(.horizontal, DS.Spacing.pageMargin)
            }
        }
    }

    private var emptyTransactionsView: some View {
        VStack(spacing: DS.Spacing.s3) {
            Image(systemName: "creditcard")
                .font(.system(size: 40))
                .foregroundStyle(Color.DS.Text.tertiary)
            Text("No transactions yet")
                .font(.subheadline)
                .foregroundStyle(Color.DS.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s10)
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .padding(.horizontal, DS.Spacing.pageMargin)
    }
}

// MARK: - Transaction Row

private struct TransactionRow: View {
    let transaction: WalletTransaction

    var body: some View {
        HStack(spacing: DS.Spacing.s3) {
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
                    .foregroundStyle(Color.DS.Text.primary)
                if let notes = transaction.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.DS.Text.secondary)
                } else {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(Color.DS.Text.tertiary)
                }
            }

            Spacer()

            Text(
                (transaction.isCredit ? "+" : "-")
                    + transaction.amountFormatted
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                transaction.isCredit
                    ? Color.DS.Semantic.success
                    : Color.DS.Semantic.error
            )
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s3)
    }

    private var iconName: String {
        switch transaction.type {
        case .topUp:
            return "arrow.down.circle.fill"
        case .stake:
            return "trophy.circle.fill"
        case .stakeRefund:
            return "arrow.counterclockwise.circle.fill"
        case .winnings:
            return "star.circle.fill"
        case .withdrawal:
            return "arrow.up.circle.fill"
        }
    }

    private var iconBackgroundColor: Color {
        switch transaction.type {
        case .topUp, .winnings:
            return Color.DS.Semantic.success
        case .stake:
            return Color.DS.Brand.primary
        case .stakeRefund:
            return Color.DS.Semantic.warning
        case .withdrawal:
            return Color.DS.Semantic.error
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
