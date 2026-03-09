import SwiftUI

// MARK: - JoinPaidLeagueView

struct JoinPaidLeagueView: View {
    @StateObject var viewModel = JoinPaidLeagueViewModel()
    @Environment(\.dismiss)
    var dismiss

    var onJoined: ((JoinPaidLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.DS.Background.primary.ignoresSafeArea()

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
                            .foregroundStyle(Color.DS.Text.secondary)
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

                VStack(spacing: DS.Spacing.s4) {
                    prizePotCard
                    walletBalanceRow
                    rulesCard
                }

                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                VStack(spacing: DS.Spacing.s3) {
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
                .padding(.bottom, DS.Spacing.s8)
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
    }

    private var prizePotCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Prize Pot")
                .font(.DS.headline)
                .foregroundStyle(Color.DS.Text.primary)

            Divider().background(Color.DS.separator)

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
        .padding(DS.Spacing.s4)
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var walletBalanceRow: some View {
        HStack {
            Text("Your wallet")
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Text.secondary)
            Spacer()
            Text(viewModel.walletBalanceFormatted)
                .font(.DS.headline)
                .foregroundStyle(
                    viewModel.hasInsufficientFunds
                        ? Color.DS.Semantic.error
                        : Color.DS.Semantic.success
                )
        }
        .padding(DS.Spacing.s4)
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("Rules")
                .font(.DS.caption1)
                .foregroundStyle(Color.DS.Text.secondary)

            ruleItem(
                icon: "theatermasks",
                text: "You play pseudonymously"
            )
            ruleItem(
                icon: "arrow.triangle.2.circlepath",
                text: "No repeat picks per round"
            )
            ruleItem(
                icon: "person.2",
                text: "League starts when 5 players join"
            )
        }
        .padding(DS.Spacing.s4)
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
