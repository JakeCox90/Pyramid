import SwiftUI

// MARK: - Dark theme colour constants (shared across JoinPaidLeagueView files)

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

// MARK: - JoinPaidLeagueView state views

extension JoinPaidLeagueView {

    // MARK: - State 2: Waiting

    func waitingStateView(
        result: JoinPaidLeagueResponse
    ) -> some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Colors.successGreen.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: Theme.Icon.Status.success)
                    .font(.system(size: 56))
                    .foregroundStyle(Colors.successGreen)
                    .pulsing()
            }

            VStack(spacing: Theme.Spacing.s20) {
                Text("You're in!")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Colors.textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Colors.textSecondary)
            }

            playerCountCard(result: result)

            Text("Starts when 5 players join")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") {
                onJoined?(result)
                dismiss()
            }
            .dsStyle(.primary)
            .padding(.bottom, Theme.Spacing.s70)
            .padding(.horizontal, Theme.Spacing.s40)
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    func playerCountCard(
        result: JoinPaidLeagueResponse
    ) -> some View {
        let total = 5
        let current = min(result.playerCount, total)
        let progress = Double(current) / Double(total)

        return VStack(spacing: Theme.Spacing.s30) {
            HStack {
                Text("\(current) / \(total) players joined")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Colors.textPrimary)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Theme.Radius.r20)
                        .fill(Colors.bgElevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: Theme.Radius.r20)
                        .fill(Colors.brandBlue)
                        .frame(
                            width: geo.size.width * progress,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(Theme.Spacing.s40)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }

    // MARK: - State 3: Active

    func activeStateView(
        result: JoinPaidLeagueResponse
    ) -> some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            Image(systemName: Theme.Icon.League.trophyFill)
                .font(.system(size: 64))
                .foregroundStyle(Colors.warningYellow)

            VStack(spacing: Theme.Spacing.s20) {
                Text("Round started!")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Colors.textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Colors.textSecondary)
            }

            infoChip(
                label: "League ID",
                value: result.leagueId
            )

            Spacer()

            VStack(spacing: Theme.Spacing.s30) {
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
            .padding(.bottom, Theme.Spacing.s70)
            .padding(.horizontal, Theme.Spacing.s40)
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }
}

// MARK: - JoinPaidLeagueView helper subviews

extension JoinPaidLeagueView {
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Colors.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Colors.textPrimary)
        }
    }

    func ruleItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s20) {
            Image(systemName: icon)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Colors.brandBlue)
                .frame(width: 16)
            Text(text)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Colors.textSecondary)
        }
    }

    func errorBanner(message: String) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: Theme.Icon.Status.errorFill)
                .foregroundStyle(Colors.errorRed)
            Text(message)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Colors.textPrimary)
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Colors.errorRed.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r20))
    }

    func infoChip(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text(label)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Colors.textSecondary)
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundStyle(Colors.textPrimary)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }
}

// MARK: - Pulse animation modifier

struct PulsingModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 0.85 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

extension View {
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
}
