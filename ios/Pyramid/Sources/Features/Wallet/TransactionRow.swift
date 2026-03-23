import SwiftUI

struct TransactionRow: View {
    let transaction: WalletTransaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName)
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(iconBackgroundColor)
            }
            .accessibilityLabel(transactionTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text(transactionTitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                if let notes = transaction.notes {
                    Text(notes)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                } else {
                    Text(formattedDate)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }
            }

            Spacer()

            Text((transaction.isCredit ? "+" : "-") + transaction.amountFormatted)
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    transaction.isCredit
                        ? Theme.Color.Status.Success.resting
                        : Theme.Color.Status.Error.resting
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
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
