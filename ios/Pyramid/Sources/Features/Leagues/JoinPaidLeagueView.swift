import SwiftUI

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
            .animation(
                .easeInOut(duration: 0.25),
                value: viewModel.joinResult == nil
            )
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
            VStack(spacing: Theme.Spacing.s60) {
                Spacer(minLength: Theme.Spacing.s70)

                VStack(spacing: Theme.Spacing.s40) {
                    prizePotCard
                    walletBalanceRow
                    rulesCard
                }

                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                VStack(spacing: Theme.Spacing.s30) {
                    Button("Confirm — Pay £5") {
                        Task { await viewModel.joinLeague() }
                    }
                    .dsStyle(
                        .primary,
                        isLoading: viewModel.isLoading
                    )
                    .disabled(
                        viewModel.isLoading ||
                        viewModel.hasInsufficientFunds
                    )

                    if viewModel.hasInsufficientFunds {
                        Button("Top Up Wallet") {
                            dismiss()
                        }
                        .dsStyle(.secondary)
                    }
                }
                .padding(.bottom, Theme.Spacing.s70)
            }
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }

    private var prizePotCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            Text("Prize Pot")
                .font(Theme.Typography.headline)
                .foregroundStyle(Colors.textPrimary)

            Divider().background(Colors.separator)

            infoRow(label: "Entry fee", value: "£5.00")
            infoRow(
                label: "Prize pot",
                value: viewModel.estimatedPrizePot
            )
            infoRow(
                label: "Top 3 split",
                value: "65% / 25% / 10%"
            )
        }
        .padding(Theme.Spacing.s40)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }

    private var walletBalanceRow: some View {
        HStack {
            Text("Your wallet")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Colors.textSecondary)
            Spacer()
            Text(viewModel.walletBalanceFormatted)
                .font(Theme.Typography.headline)
                .foregroundStyle(
                    viewModel.hasInsufficientFunds
                        ? Colors.errorRed : Colors.successGreen
                )
        }
        .padding(Theme.Spacing.s40)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Rules")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Colors.textSecondary)

            ruleItem(
                icon: Theme.Icon.Pick.pseudonymous,
                text: "You play pseudonymously"
            )
            ruleItem(
                icon: Theme.Icon.Pick.noRepeat,
                text: "No repeat picks per round"
            )
            ruleItem(
                icon: Theme.Icon.League.members,
                text: "League starts when 5 players join"
            )
        }
        .padding(Theme.Spacing.s40)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }
}
