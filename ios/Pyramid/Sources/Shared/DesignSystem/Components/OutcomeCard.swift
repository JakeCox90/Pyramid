import SwiftUI

/// Displays a match outcome — survival or elimination — as a dramatic
/// full-height card.  Replaces the former `SurvivalCard` and
/// `EliminationCard`, which were structurally identical.
struct OutcomeCard: View {
    enum Variant {
        case survived
        case eliminated
    }

    let variant: Variant
    let leagueName: String
    let gameweekName: String
    let pickedTeamName: String
    let pickedTeamLogo: String?
    let opponentName: String
    let homeTeamName: String
    let homeTeamShort: String
    let homeTeamLogo: String?
    let awayTeamName: String
    let awayTeamShort: String
    let awayTeamLogo: String?
    let homeScore: Int
    let awayScore: Int
    var pickedHome: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Spacer().frame(height: Theme.Spacing.s40)
            scoreSection
            Spacer().frame(height: Theme.Spacing.s30)
            detailSection
            Spacer()
            footerPill
        }
        .frame(maxWidth: .infinity)
        .frame(height: 446)
        .background(backgroundGradient)
        .clipShape(
            RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    accentColor.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Variant-driven properties

private extension OutcomeCard {
    var accentColor: Color {
        switch variant {
        case .survived:
            Theme.Color.Match.Pill.positive
        case .eliminated:
            Theme.Color.Match.Pill.negative
        }
    }

    var headerIcon: String {
        switch variant {
        case .survived: "checkmark.seal.fill"
        case .eliminated: "xmark.seal.fill"
        }
    }

    var headerLabel: String {
        switch variant {
        case .survived: "SURVIVED"
        case .eliminated: "ELIMINATED"
        }
    }

    var pickIcon: String {
        switch variant {
        case .survived: "checkmark.circle.fill"
        case .eliminated: "xmark.circle.fill"
        }
    }

    var backgroundGradient: some View {
        let topColor: Color = switch variant {
        case .survived:
            Theme.Color.Match.Gradient.liveStart
        case .eliminated:
            Theme.Color.Elimination.accent
        }
        return LinearGradient(
            stops: [
                .init(color: topColor, location: 0.0),
                .init(
                    color: Theme.Color.Surface
                        .Background.page,
                    location: 0.72
                )
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

// MARK: - Subviews

private extension OutcomeCard {
    var headerSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Image(systemName: headerIcon)
                .font(.system(size: 56))
                .foregroundStyle(accentColor)
                .padding(.top, Theme.Spacing.s60)

            Text(headerLabel)
                .font(Theme.Typography.overline)
                .tracking(2)
                .foregroundStyle(accentColor)

            Text(leagueName)
                .font(Theme.Typography.h3)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .lineLimit(1)
                .padding(
                    .horizontal, Theme.Spacing.s40
                )
        }
    }

    var scoreSection: some View {
        HStack(spacing: 0) {
            // Home side
            HStack(spacing: Theme.Spacing.s20) {
                TeamBadge(
                    teamName: homeTeamName,
                    logoURL: homeTeamLogo,
                    size: 36
                )
                Text(homeTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Score
            HStack(spacing: Theme.Spacing.s10) {
                pickIndicator(isHome: true)
                Text("\(homeScore)")
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
                Text("\(awayScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .monospacedDigit()
                pickIndicator(isHome: false)
            }

            // Away side
            HStack(spacing: Theme.Spacing.s20) {
                Spacer()
                Text(awayTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                TeamBadge(
                    teamName: awayTeamName,
                    logoURL: awayTeamLogo,
                    size: 36
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    @ViewBuilder
    func pickIndicator(isHome: Bool) -> some View {
        if pickedHome == isHome {
            Image(systemName: pickIcon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
        }
    }

    var detailSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text("Your pick: \(pickedTeamName)")
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            Text(gameweekName)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.tertiary
                )
        }
    }

    var footerPill: some View {
        HStack(spacing: Theme.Spacing.s10) {
            Image(systemName: pickIcon)
                .font(.system(size: 14))
            Text(headerLabel)
                .font(Theme.Typography.label01)
        }
        .foregroundStyle(
            Theme.Color.Content.Text.default
        )
        .padding(
            .horizontal, Theme.Spacing.s40
        )
        .padding(
            .vertical, Theme.Spacing.s20
        )
        .background(
            Capsule().fill(accentColor)
        )
        .padding(.bottom, Theme.Spacing.s60)
    }
}

// MARK: - Factory from LeagueResult

extension OutcomeCard {
    static func from(
        result: LeagueResult,
        variant: Variant
    ) -> OutcomeCard {
        let pickedTeamLogo: String?
        if result.pickedHome {
            pickedTeamLogo = result.homeTeamLogo
        } else {
            pickedTeamLogo = result.awayTeamLogo
        }
        return OutcomeCard(
            variant: variant,
            leagueName: result.leagueName,
            gameweekName: result.gameweekName,
            pickedTeamName: result.teamName,
            pickedTeamLogo: pickedTeamLogo,
            opponentName: result.pickedHome
                ? result.awayTeamName
                : result.homeTeamName,
            homeTeamName: result.homeTeamName,
            homeTeamShort: result.homeTeamShort,
            homeTeamLogo: result.homeTeamLogo,
            awayTeamName: result.awayTeamName,
            awayTeamShort: result.awayTeamShort,
            awayTeamLogo: result.awayTeamLogo,
            homeScore: result.homeScore,
            awayScore: result.awayScore,
            pickedHome: result.pickedHome
        )
    }
}
