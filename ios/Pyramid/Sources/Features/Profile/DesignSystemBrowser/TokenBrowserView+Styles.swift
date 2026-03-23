#if DEBUG
import SwiftUI

// MARK: - Typography, Spacing, Radius, Shadows, Gradients, Icons

extension TokenBrowserView {

    // MARK: Typography

    var typographySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            ForEach(typographyTokens, id: \.name) { token in
                HStack(spacing: Theme.Spacing.s30) {
                    Text("Aa")
                        .font(token.font)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                        .frame(width: 64, alignment: .leading)
                    Text(token.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    Spacer()
                    Text(token.detail)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .lineLimit(1)
                }
                .padding(Theme.Spacing.s30)
                .background(
                    Theme.Color.Surface.Background.container
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Theme.Radius.r20
                    )
                )
            }
        }
    }

    private var typographyTokens: [TypographyToken] {
        [
            .init(
                name: "display",
                font: Theme.Typography.display,
                detail: "Bold 54/65"
            ),
            .init(
                name: "h1",
                font: Theme.Typography.h1,
                detail: "Bold 44/53"
            ),
            .init(
                name: "h2",
                font: Theme.Typography.h2,
                detail: "Bold 32/39"
            ),
            .init(
                name: "h3",
                font: Theme.Typography.h3,
                detail: "Bold 24/29"
            ),
            .init(
                name: "subhead",
                font: Theme.Typography.subhead,
                detail: "Bold 16/19"
            ),
            .init(
                name: "overline",
                font: Theme.Typography.overline,
                detail: "Bold 12/15"
            ),
            .init(
                name: "label01",
                font: Theme.Typography.label01,
                detail: "Bold 12/15"
            ),
            .init(
                name: "label02",
                font: Theme.Typography.label02,
                detail: "Bold 12/18"
            ),
            .init(
                name: "body",
                font: Theme.Typography.body,
                detail: "Medium 14/20"
            ),
            .init(
                name: "caption",
                font: Theme.Typography.caption,
                detail: "Regular 12/15"
            )
        ]
    }

    // MARK: Spacing

    var spacingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            ForEach(spacingTokens, id: \.name) { token in
                HStack(spacing: Theme.Spacing.s30) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Color.Primary.resting)
                        .frame(width: max(token.value, 4), height: 20)
                    Text(token.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    Spacer()
                    Text("\(Int(token.value))pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .monospacedDigit()
                }
            }
        }
    }

    private var spacingTokens: [SpacingToken] {
        [
            .init(name: "s0", value: Theme.Spacing.s0),
            .init(name: "s10", value: Theme.Spacing.s10),
            .init(name: "s20", value: Theme.Spacing.s20),
            .init(name: "s30", value: Theme.Spacing.s30),
            .init(name: "s40", value: Theme.Spacing.s40),
            .init(name: "s50", value: Theme.Spacing.s50),
            .init(name: "s60", value: Theme.Spacing.s60),
            .init(name: "s70", value: Theme.Spacing.s70),
            .init(name: "s80", value: Theme.Spacing.s80),
            .init(name: "s90", value: Theme.Spacing.s90),
            .init(name: "s100", value: Theme.Spacing.s100),
            .init(name: "s110", value: Theme.Spacing.s110),
            .init(name: "s120", value: Theme.Spacing.s120),
            .init(name: "s130", value: Theme.Spacing.s130)
        ]
    }

    // MARK: Radius

    var radiusSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            ForEach(radiusTokens, id: \.name) { token in
                HStack(spacing: Theme.Spacing.s30) {
                    RoundedRectangle(
                        cornerRadius: token.value
                    )
                    .fill(Theme.Color.Primary.resting)
                    .frame(width: 36, height: 36)
                    Text(token.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    Spacer()
                    Text("\(Int(token.value))pt")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .monospacedDigit()
                }
            }
        }
    }

    private var radiusTokens: [SpacingToken] {
        [
            .init(name: "none", value: Theme.Radius.none),
            .init(name: "r05", value: Theme.Radius.r05),
            .init(name: "r10", value: Theme.Radius.r10),
            .init(name: "r20", value: Theme.Radius.r20),
            .init(name: "r30", value: Theme.Radius.r30),
            .init(name: "r40", value: Theme.Radius.r40),
            .init(name: "r45", value: Theme.Radius.r45),
            .init(name: "r50", value: Theme.Radius.r50),
            .init(name: "r60", value: Theme.Radius.r60),
            .init(name: "default", value: Theme.Radius.default),
            .init(name: "pill", value: Theme.Radius.pill),
            .init(name: "full", value: Theme.Radius.full)
        ]
    }

    // MARK: Shadows

    var shadowSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            ForEach(shadowTokens, id: \.name) { token in
                HStack(spacing: Theme.Spacing.s30) {
                    RoundedRectangle(
                        cornerRadius: Theme.Radius.r20
                    )
                    .fill(
                        Theme.Color.Surface.Background.container
                    )
                    .frame(width: 48, height: 48)
                    .themeShadow(token.style)
                    Text(token.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.s20)
            }
        }
    }

    private var shadowTokens: [ShadowToken] {
        [
            .init(name: "sm", style: Theme.Shadow.sm),
            .init(name: "md", style: Theme.Shadow.md),
            .init(name: "lg", style: Theme.Shadow.lg)
        ]
    }

    // MARK: Gradient

    var gradientSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            HStack(spacing: Theme.Spacing.s30) {
                RoundedRectangle(cornerRadius: Theme.Radius.r20)
                    .fill(Theme.Gradient.primary)
                    .frame(width: 48, height: 48)
                Text("primary")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Spacer()
                Text("linear-gradient")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
        }
    }

    // MARK: Icons

    var iconSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
            IconGroup(title: "Navigation", icons: [
                ("home", Theme.Icon.Navigation.home),
                ("leagues", Theme.Icon.Navigation.leagues),
                ("profile", Theme.Icon.Navigation.profile),
                (
                    "notifications",
                    Theme.Icon.Navigation.notifications
                ),
                (
                    "notifDisabled",
                    Theme.Icon.Navigation.notificationsDisabled
                ),
                (
                    "disclosure",
                    Theme.Icon.Navigation.disclosure
                ),
                ("add", Theme.Icon.Navigation.add)
            ])

            IconGroup(title: "League", icons: [
                ("trophy", Theme.Icon.League.trophy),
                ("trophyFill", Theme.Icon.League.trophyFill),
                (
                    "trophyCircle",
                    Theme.Icon.League.trophyCircle
                ),
                ("members", Theme.Icon.League.members),
                ("join", Theme.Icon.League.join),
                ("create", Theme.Icon.League.create),
                ("paid", Theme.Icon.League.paid)
            ])

            IconGroup(title: "Pick", icons: [
                ("gameweek", Theme.Icon.Pick.gameweek),
                ("deadline", Theme.Icon.Pick.deadline),
                (
                    "timeRemaining",
                    Theme.Icon.Pick.timeRemaining
                ),
                ("locked", Theme.Icon.Pick.locked),
                (
                    "pseudonymous",
                    Theme.Icon.Pick.pseudonymous
                ),
                ("noRepeat", Theme.Icon.Pick.noRepeat),
                ("history", Theme.Icon.Pick.history)
            ])

            IconGroup(title: "Wallet", icons: [
                ("empty", Theme.Icon.Wallet.empty),
                ("topUp", Theme.Icon.Wallet.topUp),
                (
                    "withdrawal",
                    Theme.Icon.Wallet.withdrawal
                ),
                ("refund", Theme.Icon.Wallet.refund),
                ("winnings", Theme.Icon.Wallet.winnings)
            ])

            IconGroup(title: "Action", icons: [
                ("copy", Theme.Icon.Action.copy),
                ("copied", Theme.Icon.Action.copied),
                ("share", Theme.Icon.Action.share)
            ])

            IconGroup(title: "Status", icons: [
                ("success", Theme.Icon.Status.success),
                ("failure", Theme.Icon.Status.failure),
                ("error", Theme.Icon.Status.error),
                ("errorFill", Theme.Icon.Status.errorFill),
                ("info", Theme.Icon.Status.info)
            ])
        }
    }
}

// MARK: - Supporting Types

private struct TypographyToken {
    let name: String
    let font: Font
    let detail: String
}

struct SpacingToken {
    let name: String
    let value: CGFloat
}

private struct ShadowToken {
    let name: String
    let style: Theme.Shadow.Style
}

private struct IconGroup: View {
    let title: String
    let icons: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            SubsectionHeader(title: title)
            VStack(spacing: Theme.Spacing.s10) {
                ForEach(icons, id: \.0) { name, symbol in
                    HStack(spacing: Theme.Spacing.s30) {
                        Image(systemName: symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                Theme.Color.Surface.Background
                                    .container
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: Theme.Radius.r10
                                )
                            )
                        Text(name)
                            .font(Theme.Typography.body)
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )
                        Spacer()
                        Text(symbol)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(
                                Theme.Color.Content.Text.subtle
                            )
                    }
                }
            }
        }
    }
}
#endif
