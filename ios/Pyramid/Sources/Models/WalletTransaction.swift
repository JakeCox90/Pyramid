import Foundation

// MARK: - Transaction Type

enum WalletTransactionType: String, Codable {
    case topUp = "top_up"
    case stake
    case stakeRefund = "stake_refund"
    case winnings
    case withdrawal
}

// MARK: - Transaction

struct WalletTransaction: Codable, Identifiable {
    let id: String
    let type: WalletTransactionType
    let amountPence: Int
    let createdAt: Date
    let notes: String?
    let disputeWindowExpiresAt: Date?

    var amountFormatted: String {
        String(format: "£%.2f", Double(amountPence) / 100)
    }

    var isCredit: Bool {
        switch type {
        case .topUp, .stakeRefund, .winnings:
            return true
        case .stake, .withdrawal:
            return false
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case amountPence = "amount_pence"
        case createdAt = "created_at"
        case notes
        case disputeWindowExpiresAt = "dispute_window_expires_at"
    }
}
