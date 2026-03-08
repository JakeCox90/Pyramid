import Foundation

struct WalletBalance: Codable {
    let availableToPlayPence: Int
    let withdrawablePence: Int
    let pendingPence: Int

    var availableToPlayFormatted: String { formatPence(availableToPlayPence) }
    var withdrawableFormatted: String { formatPence(withdrawablePence) }
    var pendingFormatted: String { formatPence(pendingPence) }

    private func formatPence(_ pence: Int) -> String {
        String(format: "£%.2f", Double(pence) / 100)
    }

    enum CodingKeys: String, CodingKey {
        case availableToPlayPence = "available_to_play_pence"
        case withdrawablePence = "withdrawable_pence"
        case pendingPence = "pending_pence"
    }
}
