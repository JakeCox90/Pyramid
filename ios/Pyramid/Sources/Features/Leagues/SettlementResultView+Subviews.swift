import SwiftUI

// MARK: - Hero Section

struct SettlementHeroSection: View {
    let data: SettlementResultData

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0

    private var isSurvived: Bool { data.result == .survived }

    var body: some View {
        VStack(spacing: Theme.Spacing.s40) {
            iconView
            titleView
            scoreView
        }
        .frame(maxWidth: .infinity)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 120, height: 120)

            Image(systemName: isSurvived ? Theme.Icon.Status.success : Theme.Icon.Status.failure)
                .font(.system(size: 56))
                .foregroundStyle(iconColor)
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }

    private var titleView: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text(isSurvived
                ? NSLocalizedString(
                    "settlement.title.survived",
                    value: "You Survived!",
                    comment: "Title when player survives"
                )
                : NSLocalizedString(
                    "settlement.title.eliminated",
                    value: "Eliminated",
                    comment: "Title when player is eliminated"
                )
            )
            .font(Theme.Typography.title1)
            .foregroundStyle(Theme.Color.Content.Text.default)

            Text(
                String(
                    format: NSLocalizedString(
                        "settlement.subtitle.gameweek",
                        value: "GW%d",
                        comment: "Gameweek number subtitle"
                    ),
                    data.gameweekNumber
                )
            )
            .font(Theme.Typography.headline)
            .foregroundStyle(iconColor)

            if !data.leagueName.isEmpty {
                Text(data.leagueName)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder private var scoreView: some View {
        if !data.score.isEmpty {
            VStack(spacing: Theme.Spacing.s10) {
                Text(data.teamName)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)

                Text(data.score)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .monospacedDigit()
            }
            .padding(.horizontal, Theme.Spacing.s50)
            .padding(.vertical, Theme.Spacing.s30)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
        }
    }

    private var iconColor: Color {
        isSurvived
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }
}

// MARK: - Stats Section

struct SettlementStatsSection: View {
    let data: SettlementResultData

    private var isSurvived: Bool { data.result == .survived }

    var body: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text(
                NSLocalizedString(
                    "settlement.section.stats",
                    value: "Your result",
                    comment: "Stats section title on settlement screen"
                )
            )
            .font(Theme.Typography.caption1)
            .foregroundStyle(Theme.Color.Content.Text.disabled)
            .frame(maxWidth: .infinity, alignment: .leading)

            DSCard {
                VStack(spacing: Theme.Spacing.s30) {
                    statRow(
                        label: NSLocalizedString(
                            "settlement.stat.pick",
                            value: "Your Pick",
                            comment: "Label for pick team stat"
                        ),
                        value: data.teamName
                    )

                    if isSurvived {
                        statRow(
                            label: NSLocalizedString(
                                "settlement.stat.players_remaining",
                                value: "Players Remaining",
                                comment: "Label for players remaining stat"
                            ),
                            value: "\(data.playersRemaining)"
                        )
                    } else {
                        statRow(
                            label: NSLocalizedString(
                                "settlement.stat.gameweeks_lasted",
                                value: "Gameweeks Lasted",
                                comment: "Label for gameweeks lasted stat"
                            ),
                            value: "\(data.gameweeksLasted)"
                        )
                    }

                    statRow(
                        label: NSLocalizedString(
                            "settlement.stat.gameweek",
                            value: "Gameweek",
                            comment: "Label for gameweek number stat"
                        ),
                        value: "GW\(data.gameweekNumber)"
                    )
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
            Spacer()
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }
}

// MARK: - Actions Section

struct SettlementActionsSection: View {
    let data: SettlementResultData
    let onViewStandings: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Button(action: onViewStandings) {
                Label(
                    NSLocalizedString(
                        "settlement.action.view_standings",
                        value: "View Standings",
                        comment: "Button to view league standings"
                    ),
                    systemImage: "list.number"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint(
                NSLocalizedString(
                    "settlement.accessibility.standings_hint",
                    value: "Opens the league standings",
                    comment: "Accessibility hint for view standings button"
                )
            )

            Button(action: onShare) {
                Label(
                    NSLocalizedString(
                        "settlement.action.share",
                        value: "Share Result",
                        comment: "Button to share settlement result"
                    ),
                    systemImage: Theme.Icon.Action.share
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityHint(
                NSLocalizedString(
                    "settlement.accessibility.share_hint",
                    value: "Share your result with friends",
                    comment: "Accessibility hint for share button"
                )
            )
        }
    }
}

// MARK: - Preview

#Preview("Survived") {
    SettlementResultView(leagueId: "preview", gameweekId: 14)
}

#Preview("Eliminated") {
    SettlementResultView(leagueId: "preview-elim", gameweekId: 7)
}
