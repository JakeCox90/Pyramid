import SwiftUI

// MARK: - Dark theme colour constants (private to this file)

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

// MARK: - JoinPaidLeagueView

struct JoinPaidLeagueView: View {
    @StateObject private var viewModel = JoinPaidLeagueViewModel()
    @Environment(\.dismiss) private var dismiss

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
            .animation(.easeInOut(duration: 0.25), value: viewModel.joinResult == nil)
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
                .foregroundStyle(textPrimary)

            Divider().background(separator)

            infoRow(label: "Entry fee", value: "£5.00")
            infoRow(label: "Prize pot", value: viewModel.estimatedPrizePot)
            infoRow(label: "Top 3 split", value: "65% / 25% / 10%")
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
                .foregroundStyle(viewModel.hasInsufficientFunds ? errorRed : successGreen)
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

            ruleItem(icon: "theatermasks", text: "You play pseudonymously — your identity is hidden")
            ruleItem(icon: "arrow.triangle.2.circlepath", text: "No repeat picks — each team can only be chosen once")
            ruleItem(icon: "person.2", text: "League starts when 5 players have joined")
        }
        .padding(DS.Spacing.s4)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    // MARK: - State 2: Waiting

    private func waitingStateView(result: JoinPaidLeagueResponse) -> some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            // Success icon
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

                Text("You are \(result.pseudonym) in this league")
                    .font(.DS.subheadline)
                    .foregroundStyle(textSecondary)
            }

            // Player count progress
            playerCountCard(result: result)

            Text("League starts when 5 players have joined")
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

    private func playerCountCard(result: JoinPaidLeagueResponse) -> some View {
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
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(DS.Spacing.s4)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    // MARK: - State 3: Active

    private func activeStateView(result: JoinPaidLeagueResponse) -> some View {
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

            infoChip(label: "League ID", value: result.leagueId)

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

    // MARK: - Helper views

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.DS.subheadline)
                .foregroundStyle(textSecondary)
            Spacer()
            Text(value)
                .font(.DS.subheadline)
                .foregroundStyle(textPrimary)
        }
    }

    private func ruleItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: icon)
                .font(.DS.caption1)
                .foregroundStyle(brandBlue)
                .frame(width: 16)
            Text(text)
                .font(.DS.caption1)
                .foregroundStyle(textSecondary)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(errorRed)
            Text(message)
                .font(.DS.caption1)
                .foregroundStyle(textPrimary)
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(errorRed.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    private func infoChip(label: String, value: String) -> some View {
        VStack(spacing: DS.Spacing.s1) {
            Text(label)
                .font(.DS.caption1)
                .foregroundStyle(textSecondary)
            Text(value)
                .font(.DS.headline)
                .foregroundStyle(textPrimary)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}

// MARK: - Pulse animation modifier

private struct PulsingModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 0.85 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

private extension View {
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
}
