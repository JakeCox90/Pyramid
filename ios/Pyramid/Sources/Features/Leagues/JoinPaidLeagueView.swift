import SwiftUI

// MARK: - Dark theme colour constants

enum JoinPaidLeagueColors {
    static let bgPrimary = Color(hex: "0A0A0A")
    static let bgCard = Color(hex: "1C1C1E")
    static let bgElevated = Color(hex: "2C2C2E")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let brandBlue = Color(hex: "1A56DB")
    static let successGreen = Color(hex: "30D158")
    static let errorRed = Color(hex: "FF453A")
    static let warningYellow = Color(hex: "FFD60A")
    static let separator = Color(hex: "38383A")
}

private typealias Colors = JoinPaidLeagueColors

// MARK: - JoinPaidLeagueView

struct JoinPaidLeagueView: View {
    @StateObject var viewModel = JoinPaidLeagueViewModel()
    @Environment(\.dismiss)
    var dismiss

    var onJoined: ((JoinPaidLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Colors.bgPrimary.ignoresSafeArea()

                if let result = viewModel.joinResult {
                    switch result.status {
                    case .waiting:
                        waitingStateView(result: result)
                            .transition(.opacity)
                    case .active, .complete:
                        activeStateView(result: result)
                            .transition(.opacity)
                    }
                } else {
                    confirmationView
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.joinResult == nil)
            .navigationTitle("Join Paid League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.joinResult == nil {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Colors.textSecondary)
                    }
                }
            }
            .task { await viewModel.load() }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - State 1: Confirmation

    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s6) {
                Spacer(minLength: DS.Spacing.s8)

                // Prize pot card
                VStack(spacing: DS.Spacing.s4) {
                    prizePotCard
                    walletBalanceRow
                    rulesCard
                }

                // Error banner
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                // Actions
                VStack(spacing: DS.Spacing.s3) {
                    Button("Confirm — Pay £5") {
                        Task { await viewModel.joinLeague() }
                    }
                    .dsStyle(.primary, isLoading: viewModel.isLoading)
                    .disabled(viewModel.isLoading || viewModel.hasInsufficientFunds)

                    if viewModel.hasInsufficientFunds {
                        Button("Top Up Wallet") {
                            // Navigation to wallet handled at the parent level.
                            // Dismiss this sheet so the user can navigate to wallet.
                            dismiss()
                        }
                        .dsStyle(.secondary)
                    }
                }
                .padding(.bottom, DS.Spacing.s8)
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
    }

    private var prizePotCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Prize Pot")
                .font(.DS.headline)
                .foregroundStyle(Colors.textPrimary)

            Divider().background(Colors.separator)

            infoRow(label: "Entry fee", value: "£5.00")
            infoRow(label: "Prize pot", value: viewModel.estimatedPrizePot)
            infoRow(label: "Top 3 split", value: "65% / 25% / 10%")
        }
        .padding(DS.Spacing.s4)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var walletBalanceRow: some View {
        HStack {
            Text("Your wallet")
                .font(.DS.subheadline)
                .foregroundStyle(Colors.textSecondary)
            Spacer()
            Text(viewModel.walletBalanceFormatted)
                .font(.DS.headline)
                .foregroundStyle(viewModel.hasInsufficientFunds ? Colors.errorRed : Colors.successGreen)
        }
        .padding(DS.Spacing.s4)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("Rules")
                .font(.DS.caption1)
                .foregroundStyle(Colors.textSecondary)

            ruleItem(icon: "theatermasks", text: "You play pseudonymously — your identity is hidden")
            ruleItem(icon: "arrow.triangle.2.circlepath", text: "No repeat picks — each team can only be chosen once")
            ruleItem(icon: "person.2", text: "League starts when 5 players have joined")
        }
        .padding(DS.Spacing.s4)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

}
