import SwiftUI

// MARK: - Live Match Cards

extension HomeView {
    @ViewBuilder
    func liveMatchSection() -> some View {
        let contexts = viewModel.livePickContexts
        if !contexts.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
                HStack(spacing: Theme.Spacing.s20) {
                    PulsingDot()
                    Text("Live Now")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                }

                ForEach(contexts) { context in
                    liveMatchCard(context)
                }
            }
        }
    }

    @ViewBuilder
    private func liveMatchCard(
        _ context: LivePickContext
    ) -> some View {
        let surviving = context.isSurviving

        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            liveMatchHeader(context)
            liveMatchScoreRow(context)
            liveMatchSurvival(surviving)
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
                .strokeBorder(
                    liveBorderColor(surviving),
                    lineWidth: 1.5
                )
        )
    }

    @ViewBuilder
    private func liveMatchHeader(
        _ context: LivePickContext
    ) -> some View {
        HStack {
            Text(context.leagueName)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .textCase(.uppercase)

            Spacer()

            PulsingDot()

            Text(context.fixture.status.displayLabel)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Error.resting)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func liveMatchScoreRow(
        _ context: LivePickContext
    ) -> some View {
        let homeScore = context.fixture.homeScore ?? 0
        let awayScore = context.fixture.awayScore ?? 0

        HStack {
            Text(context.fixture.homeTeamShort)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)

            Spacer()

            Text("\(homeScore)  \u{2013}  \(awayScore)")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .monospacedDigit()

            Spacer()

            Text(context.fixture.awayTeamShort)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
    }

    @ViewBuilder
    private func liveMatchSurvival(_ surviving: Bool?) -> some View {
        if let surviving {
            HStack(spacing: Theme.Spacing.s10) {
                Image(
                    systemName: surviving
                        ? "checkmark.circle.fill"
                        : "xmark.circle.fill"
                )
                Text(surviving ? "Surviving" : "In Danger")
                    .font(Theme.Typography.subheadline)
            }
            .foregroundStyle(
                surviving
                    ? Theme.Color.Status.Success.resting
                    : Theme.Color.Status.Error.resting
            )
        }
    }

    private func liveBorderColor(_ surviving: Bool?) -> Color {
        guard let surviving else { return Color.clear }
        return surviving
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }
}
