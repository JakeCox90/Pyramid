import SwiftUI

private let bgPrimary = Color(hex: "0A0A0A")
private let bgCard = Color(hex: "1C1C1E")
private let bgElevated = Color(hex: "2C2C2E")
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.6)
private let brandBlue = Color(hex: "1A56DB")
private let successGreen = Color(hex: "30D158")
private let errorRed = Color(hex: "FF453A")
private let warningYellow = Color(hex: "FFD60A")
private let separator = Color(hex: "38383A")

struct JoinPaidLeagueView: View {
    @StateObject private var viewModel = JoinPaidLeagueViewModel()

    @Environment(\.dismiss)
    private var dismiss

    var onJoined: ((JoinPaidLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                bgPrimary.ignoresSafeArea()

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
                            .foregroundStyle(textSecondary)
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
                .foregroundStyle(textPrimary)

            Divider().background(separator)

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
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var walletBalanceRow: some View {
        HStack {
            Text("Your wallet")
                .font(.DS.subheadline)
                .foregroundStyle(textSecondary)
            Spacer()
            Text(viewModel.walletBalanceFormatted)
                .font(.DS.headline)
                .foregroundStyle(
                    viewModel.hasInsufficientFunds
                        ? errorRed : successGreen
                )
        }
        .padding(DS.Spacing.s4)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("Rules")
                .font(.DS.caption1)
                .foregroundStyle(textSecondary)

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
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    // MARK: - State 2: Waiting

    private func waitingStateView(
        result: JoinPaidLeagueResponse
    ) -> some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            ZStack {
                Circle()
                    .fill(successGreen.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(successGreen)
                    .pulsing()
            }

            VStack(spacing: DS.Spacing.s2) {
                Text("You're in!")
                    .font(.DS.title1)
                    .foregroundStyle(textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(.DS.subheadline)
                    .foregroundStyle(textSecondary)
            }

            playerCountCard(result: result)

            Text("Starts when 5 players join")
                .font(.DS.caption1)
                .foregroundStyle(textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") {
                onJoined?(result)
                dismiss()
            }
            .dsStyle(.primary)
            .padding(.bottom, DS.Spacing.s8)
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    private func playerCountCard(
        result: JoinPaidLeagueResponse
    ) -> some View {
        let total = 5
        let current = min(result.playerCount, total)
        let progress = Double(current) / Double(total)

        return VStack(spacing: DS.Spacing.s3) {
            HStack {
                Text("\(current) / \(total) players joined")
                    .font(.DS.headline)
                    .foregroundStyle(textPrimary)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(bgElevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(brandBlue)
                        .frame(
                            width: geo.size.width * progress,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(DS.Spacing.s4)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    // MARK: - State 3: Active

    private func activeStateView(
        result: JoinPaidLeagueResponse
    ) -> some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(warningYellow)

            VStack(spacing: DS.Spacing.s2) {
                Text("Round started!")
                    .font(.DS.title1)
                    .foregroundStyle(textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(.DS.subheadline)
                    .foregroundStyle(textSecondary)
            }

            infoChip(
                label: "League ID",
                value: result.leagueId
            )

            Spacer()

            VStack(spacing: DS.Spacing.s3) {
                Button("View League") {
                    onJoined?(result)
                    dismiss()
                }
                .dsStyle(.primary)

                Button("Done") {
                    dismiss()
                }
                .dsStyle(.ghost)
            }
            .padding(.bottom, DS.Spacing.s8)
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }
}
