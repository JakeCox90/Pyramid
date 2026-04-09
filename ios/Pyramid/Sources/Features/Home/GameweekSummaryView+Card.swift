import SwiftUI

// MARK: - Summary Card Content

extension GameweekSummaryView {
    func summaryCard(
        _ item: GameweekSummaryItem
    ) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            Text(item.leagueName)
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            resultIcon(item)

            Text(
                item.result == .survived
                    ? "SURVIVED"
                    : "ELIMINATED"
            )
            .font(Theme.Typography.h2)
            .foregroundStyle(resultColor(item))

            scoreBlock(item)

            supportingPills(item)
        }
        .padding(.vertical, Theme.Spacing.s60)
        .padding(.horizontal, Theme.Spacing.s40)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r50
            )
        )
    }
}

// MARK: - Card Subviews

extension GameweekSummaryView {
    private func resultIcon(
        _ item: GameweekSummaryItem
    ) -> some View {
        Image(
            systemName: item.result == .survived
                ? "checkmark.seal.fill"
                : "xmark.seal.fill"
        )
        .font(.system(size: 60))
        .foregroundStyle(resultColor(item))
        .shadow(
            color: resultShadow(item),
            radius: 20
        )
    }

    private func scoreBlock(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: 0) {
            homeTeamSide(item)
            scoreCentre(item)
            awayTeamSide(item)
        }
    }

    private func homeTeamSide(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            TeamBadge(
                teamName: item.homeTeamName,
                logoURL: item.homeTeamLogo,
                size: 32
            )
            Text(item.homeTeamShort)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreCentre(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: Theme.Spacing.s10) {
            if item.pickedHome {
                pickDot(item)
            }
            Text("\(item.homeScore)")
                .font(Theme.Typography.h2)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .monospacedDigit()
            Text("\u{2013}")
                .font(Theme.Typography.h3)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
            Text("\(item.awayScore)")
                .font(Theme.Typography.h2)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .monospacedDigit()
            if !item.pickedHome {
                pickDot(item)
            }
        }
    }

    private func awayTeamSide(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Spacer()
            Text(item.awayTeamShort)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            TeamBadge(
                teamName: item.awayTeamName,
                logoURL: item.awayTeamLogo,
                size: 32
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func supportingPills(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            pill(
                text: item.result == .survived
                    ? "Streak: \(item.survivalStreak)"
                    : "Streak ended",
                color: resultColor(item)
            )
            pill(
                text: "\(item.playersRemaining) of \(item.totalPlayers) left",
                color: Theme.Color.Content.Text.subtle
            )
        }
    }

    private func pickDot(
        _ item: GameweekSummaryItem
    ) -> some View {
        Image(
            systemName: item.result == .survived
                ? "checkmark.circle.fill"
                : "xmark.circle.fill"
        )
        .font(.system(size: 14))
        .foregroundStyle(resultColor(item))
    }

    private func pill(
        text: String,
        color: Color
    ) -> some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.vertical, Theme.Spacing.s10)
            .padding(.horizontal, Theme.Spacing.s20)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    func resultColor(
        _ item: GameweekSummaryItem
    ) -> Color {
        item.result == .survived
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }

    private func resultShadow(
        _ item: GameweekSummaryItem
    ) -> Color {
        item.result == .survived
            ? Theme.Color.Status.Success.resting.opacity(0.6)
            : Theme.Color.Status.Error.resting.opacity(0.6)
    }
}
