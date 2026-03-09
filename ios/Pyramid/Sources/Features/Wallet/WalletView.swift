import SwiftUI

// MARK: - Wallet Colours

private let bgPrimary = Color(hex: "0A0A0A")
private let bgCard = Color(hex: "1C1C1E")
private let bgElevated = Color(hex: "2C2C2E")
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.6)
private let textTertiary = Color.white.opacity(0.3)
private let brandBlue = Color(hex: "1A56DB")
private let successGreen = Color(hex: "30D158")
private let errorRed = Color(hex: "FF453A")
private let warningYellow = Color(hex: "FFD60A")
private let separator = Color(hex: "38383A")

// MARK: - WalletView

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                bgPrimary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.wallet == nil {
                    ProgressView()
                        .tint(textPrimary)
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
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Available to Play")
                    .font(.subheadline)
                    .foregroundStyle(textSecondary)
                Text(viewModel.wallet?.availableToPlayFormatted ?? "–")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(textPrimary)
            }

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("Withdrawable")
                        .font(.caption)
                        .foregroundStyle(textTertiary)
                    let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                    Text(viewModel.wallet?.withdrawableFormatted ?? "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(withdrawable > 0 ? successGreen : textSecondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(separator)
                    .frame(width: 1, height: 32)

                VStack(spacing: 2) {
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(textTertiary)
                    Text(viewModel.wallet?.pendingFormatted ?? "–")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(bgCard)
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
                        .background(brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                Button {
                    viewModel.showWithdrawSheet = true
                } label: {
                    Text("Withdraw")
                        .font(.headline)
                        .foregroundStyle(withdrawable > 0 ? textPrimary : textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(bgElevated)
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
                .foregroundStyle(textPrimary)
                .padding(.horizontal, 16)

            if viewModel.transactions.isEmpty {
                emptyTransactionsView
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != viewModel.transactions.last?.id {
                            Divider()
                                .overlay(separator)
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyTransactionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: Theme.Icon.Wallet.empty)
                .font(.system(size: 40))
                .foregroundStyle(textTertiary)
            Text("No transactions yet")
                .font(.subheadline)
                .foregroundStyle(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(bgCard)
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
                    .foregroundStyle(textPrimary)
                if let notes = transaction.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(textSecondary)
                } else {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(textTertiary)
                }
            }

            Spacer()

            Text((transaction.isCredit ? "+" : "-") + transaction.amountFormatted)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.isCredit ? successGreen : errorRed)
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
            return successGreen
        case .stake:
            return brandBlue
        case .stakeRefund:
            return warningYellow
        case .withdrawal:
            return errorRed
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
