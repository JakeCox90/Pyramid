import SwiftUI

// MARK: - My Pick Card

extension LeagueDetailView {
    @ViewBuilder var myPickCard: some View {
        if viewModel.isDeadlinePassed(), let pick = viewModel.myPick {
            MyPickCard(
                pick: pick,
                fixture: viewModel.myFixture,
                isSurviving: viewModel.isSurviving
            )
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }
}

struct MyPickCard: View {
    let pick: MemberPick
    let fixture: Fixture?
    let isSurviving: Bool?

    @State private var livePulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
                .fill(cardBackground)
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
                .strokeBorder(cardBorderColor, lineWidth: 1)
            cardContent
                .padding(Theme.Spacing.s40)
        }
        .themeShadow(Theme.Shadow.md)
    }

    // MARK: - Card Content

    @ViewBuilder private var cardContent: some View {
        if let fixture {
            if fixture.status.isLive || fixture.status.isFinished {
                liveOrFinishedContent(fixture: fixture)
            } else {
                notStartedContent(fixture: fixture)
            }
        } else {
            pickOnlyContent
        }
    }

    private func liveOrFinishedContent(fixture: Fixture) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            HStack {
                statusDot(isLive: fixture.status.isLive)
                Text(fixture.status.isLive ? "LIVE" : "FT")
                    .font(Theme.Typography.caption1)
                    .fontWeight(.bold)
                    .foregroundStyle(fixture.status.isLive
                        ? Theme.Color.Status.Error.resting
                        : Theme.Color.Content.Text.disabled)
                Spacer()
                survivalLabel
            }

            HStack(alignment: .center, spacing: Theme.Spacing.s30) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(pick.teamName)
                        .font(Theme.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    Text("My pick")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Theme.Spacing.s10) {
                    scoreView(fixture: fixture)
                    Text(fixture.status.displayLabel)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(fixture.status.isLive
                            ? Theme.Color.Status.Error.resting
                            : Theme.Color.Content.Text.disabled)
                }
            }
        }
    }

    private func notStartedContent(fixture: Fixture) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                Text(pick.teamName)
                    .font(Theme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                Text("My pick")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Spacing.s10) {
                Text(kickoffLabel(fixture: fixture))
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                Text("Kick-off")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
        }
    }

    private var pickOnlyContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                Text(pick.teamName)
                    .font(Theme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                Text("My pick")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
            Spacer()
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func statusDot(isLive: Bool) -> some View {
        if isLive {
            Circle()
                .fill(Theme.Color.Status.Error.resting)
                .frame(width: 8, height: 8)
                .scaleEffect(livePulse ? 1.4 : 1.0)
                .animation(
                    .easeInOut(duration: 1).repeatForever(autoreverses: true),
                    value: livePulse
                )
                .onAppear { livePulse = true }
        }
    }

    @ViewBuilder private var survivalLabel: some View {
        if let isSurviving {
            if isSurviving {
                HStack(spacing: Theme.Spacing.s10) {
                    Image(systemName: Theme.Icon.Status.success)
                        .foregroundStyle(Theme.Color.Status.Success.resting)
                    Text("Surviving!")
                        .font(Theme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.Status.Success.resting)
                }
            } else {
                HStack(spacing: Theme.Spacing.s10) {
                    Image(systemName: Theme.Icon.Status.failure)
                        .foregroundStyle(Theme.Color.Status.Error.resting)
                    Text("In danger!")
                        .font(Theme.Typography.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.Status.Error.resting)
                }
            }
        } else if let fixture, fixture.status.isFinished {
            finishedResultLabel
        }
    }

    @ViewBuilder private var finishedResultLabel: some View {
        if pick.result == .survived {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: Theme.Icon.Status.success)
                    .foregroundStyle(Theme.Color.Status.Success.resting)
                Text("Survived!")
                    .font(Theme.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.Status.Success.resting)
            }
        } else if pick.result == .eliminated {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: Theme.Icon.Status.failure)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
                Text("Eliminated")
                    .font(Theme.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            }
        }
    }

    private func scoreView(fixture: Fixture) -> some View {
        let homeScore = fixture.homeScore ?? 0
        let awayScore = fixture.awayScore ?? 0
        return Text("\(homeScore) - \(awayScore)")
            .font(Theme.Typography.title2)
            .fontWeight(.bold)
            .foregroundStyle(Theme.Color.Content.Text.default)
            .monospacedDigit()
    }

    private func kickoffLabel(fixture: Fixture) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: fixture.kickoffAt)
    }

    // MARK: - Card Styling

    private var cardBackground: Color {
        guard let isSurviving else {
            if let fixture, fixture.status.isFinished {
                switch pick.result {
                case .survived: return Theme.Color.Status.Success.subtle
                case .eliminated: return Theme.Color.Status.Error.subtle
                default: return Theme.Color.Surface.Background.container
                }
            }
            return Theme.Color.Surface.Background.container
        }
        return isSurviving ? Theme.Color.Status.Success.subtle : Theme.Color.Status.Error.subtle
    }

    private var cardBorderColor: Color {
        guard let isSurviving else {
            if let fixture, fixture.status.isFinished {
                switch pick.result {
                case .survived: return Theme.Color.Status.Success.resting.opacity(0.3)
                case .eliminated: return Theme.Color.Status.Error.resting.opacity(0.3)
                default: return Theme.Color.Border.default
                }
            }
            return Theme.Color.Border.default
        }
        return isSurviving
            ? Theme.Color.Status.Success.resting.opacity(0.3)
            : Theme.Color.Status.Error.resting.opacity(0.3)
    }
}
