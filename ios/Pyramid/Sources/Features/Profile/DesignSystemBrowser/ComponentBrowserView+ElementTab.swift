#if DEBUG
import SwiftUI

// MARK: - Element Tab

extension ComponentBrowserView {
    var elementContent: some View {
        Group {
            pulsingDotSection
            teamBadgeSection
            teamsUsedPillSection
        }
    }
}

// MARK: - Pulsing Dot

extension ComponentBrowserView {
    var pulsingDotSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "PulsingDot")
            HStack(spacing: Theme.Spacing.s20) {
                PulsingDot()
                Text(
                    "Live indicator (respects reduce motion)"
                )
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            }
            .padding(Theme.Spacing.s30)
            .background(
                Theme.Color.Surface.Background
                    .container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r20
                )
            )
        }
    }
}

// MARK: - TeamBadge

extension ComponentBrowserView {
    var teamBadgeSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "TeamBadge")

            HStack(spacing: Theme.Spacing.s30) {
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Arsenal",
                        logoURL: nil,
                        size: 64
                    )
                    Text("64pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Chelsea",
                        logoURL: nil,
                        size: 48
                    )
                    Text("48pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Liverpool",
                        logoURL: nil,
                        size: 36
                    )
                    Text("36pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
                VStack(spacing: Theme.Spacing.s10) {
                    TeamBadge(
                        teamName: "Unknown FC",
                        logoURL: nil,
                        size: 36
                    )
                    Text("fallback")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .subtle
                        )
                }
            }
        }
    }
}

// MARK: - TeamsUsedPill

extension ComponentBrowserView {
    var teamsUsedPillSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "TeamsUsedPill")

            TeamsUsedPill(
                teamNames: [
                    "Arsenal", "Chelsea", "Liverpool"
                ],
                count: 3
            )
            TeamsUsedPill(
                teamNames: [
                    "Arsenal", "Chelsea", "Liverpool",
                    "Tottenham", "Man City", "Everton"
                ],
                count: 6
            )
        }
    }
}
#endif
