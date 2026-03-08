import SwiftUI

// MARK: - JoinPaidLeagueViewModel

@MainActor
final class JoinPaidLeagueViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var joinResult: JoinPaidLeagueResponse?
    @Published var walletBalance: Int = 0 // pence

    private let service: PaidLeagueServiceProtocol

    // MARK: - Constants

    private static let entryFeePence: Int = 500       // £5.00
    private static let maxPlayers: Int = 30
    private static let platformFee: Double = 0.08     // 8%

    // MARK: - Init

    init(service: PaidLeagueServiceProtocol = PaidLeagueService()) {
        self.service = service
    }

    // MARK: - Computed

    var hasInsufficientFunds: Bool {
        walletBalance < Self.entryFeePence
    }

    /// "up to £150" (30 players × £5 × 0.92)
    var estimatedPrizePot: String {
        let potPence = Double(Self.maxPlayers) * Double(Self.entryFeePence) * (1 - Self.platformFee)
        let potPounds = potPence / 100
        return "up to £\(Int(potPounds))"
    }

    var walletBalanceFormatted: String {
        let pounds = Double(walletBalance) / 100
        return String(format: "£%.2f", pounds)
    }

    // MARK: - Actions

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            walletBalance = try await service.fetchWalletBalance()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func joinLeague() async {
        guard !hasInsufficientFunds else {
            errorMessage = "You don't have enough balance to join. Please top up your wallet."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            joinResult = try await service.joinPaidLeague()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
