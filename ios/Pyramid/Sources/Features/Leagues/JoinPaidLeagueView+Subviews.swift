import SwiftUI

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
                    .fill(Theme.Color.Status.Success.resting.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: Theme.Icon.Status.success)
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.Status.Success.resting)
                    .pulsing()
            }

            VStack(spacing: Theme.Spacing.s20) {
                Text("You're in!")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text("You are \(result.pseudonym)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }

            playerCountCard(result: result)

            Text("Starts when 5 players join")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
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
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Theme.Radius.r20)
                        .fill(Theme.Color.Surface.Background.container)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: Theme.Radius.r20)
                        .fill(Theme.Color.Primary.resting)
                        .frame(
                            width: geo.size.width * progress,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
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
                .foregroundStyle(Theme.Color.Status.Warning.resting)

            VStack(spacing: Theme.Spacing.s20) {
                Text("Round started!")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text("You are \(result.pseudonym)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
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
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Spacer()
            Text(value)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }

    func ruleItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s20) {
            Image(systemName: icon)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Primary.resting)
                .frame(width: 16)
            Text(text)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
    }

    func errorBanner(message: String) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: Theme.Icon.Status.errorFill)
                .foregroundStyle(Theme.Color.Status.Error.resting)
            Text(message)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Status.Error.resting.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r20))
    }

    func infoChip(label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text(label)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Text(value)
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
        .background(Theme.Color.Surface.Background.container)
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
