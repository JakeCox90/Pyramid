import SwiftUI

/// A celebratory card displayed when the user has survived a gameweek.
/// Shows the match result that confirmed survival. Green-themed
/// counterpart to `EliminationCard`.
struct SurvivalCard: View {
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
                    survivalGreen.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Subviews

private extension SurvivalCard {
    var headerSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(survivalGreen)
                .padding(.top, Theme.Spacing.s60)

            Text("SURVIVED")
                .font(Theme.Typography.overline)
                .tracking(2)
                .foregroundStyle(survivalGreen)

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
            Image(
                systemName: "checkmark.circle.fill"
            )
            .font(.system(size: 14))
            .foregroundStyle(survivalGreen)
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
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
            Text("SURVIVED")
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
            Capsule().fill(survivalGreen)
        )
        .padding(.bottom, Theme.Spacing.s60)
    }
}

// MARK: - Colours

private extension SurvivalCard {
    var survivalGreen: Color {
        Theme.Color.Match.Pill.positive
    }

    var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(
                    color: Theme.Color.Match
                        .Gradient.liveStart,
                    location: 0.0
                ),
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

// MARK: - Factory from LeagueResult

extension SurvivalCard {
    static func from(
        result: LeagueResult
    ) -> SurvivalCard {
        let pickedTeamLogo: String?
        if result.pickedHome {
            pickedTeamLogo = result.homeTeamLogo
        } else {
            pickedTeamLogo = result.awayTeamLogo
        }
        return SurvivalCard(
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
