import SwiftUI

/// A dramatic card displayed when the user has been eliminated from a league.
/// Shows the match result that caused the elimination with score details.
struct EliminationCard: View {
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
                    eliminationRed.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Subviews

private extension EliminationCard {
    var headerSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Image(systemName: "xmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(eliminationRed)
                .padding(.top, Theme.Spacing.s60)

            Text("ELIMINATED")
                .font(Theme.Typography.overline)
                .tracking(2)
                .foregroundStyle(eliminationRed)

            Text(leagueName)
                .font(Theme.Typography.h3)
                .foregroundStyle(.white)
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
                    .foregroundStyle(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Score
            HStack(spacing: Theme.Spacing.s10) {
                pickIndicator(isHome: true)
                Text("\(homeScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("\u{2013}")
                    .font(Theme.Typography.h3)
                    .foregroundStyle(
                        .white.opacity(0.4)
                    )
                Text("\(awayScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                pickIndicator(isHome: false)
            }

            // Away side
            HStack(spacing: Theme.Spacing.s20) {
                Spacer()
                Text(awayTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(.white)
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
                systemName: "xmark.circle.fill"
            )
            .font(.system(size: 14))
            .foregroundStyle(eliminationRed)
        }
    }

    var detailSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text("Your pick: \(pickedTeamName)")
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    .white.opacity(0.6)
                )

            Text(gameweekName)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    .white.opacity(0.3)
                )
        }
    }

    var footerPill: some View {
        HStack(spacing: Theme.Spacing.s10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
            Text("ELIMINATED")
                .font(Theme.Typography.label01)
        }
        .foregroundStyle(.white)
        .padding(
            .horizontal, Theme.Spacing.s40
        )
        .padding(
            .vertical, Theme.Spacing.s20
        )
        .background(
            Capsule().fill(eliminationRed)
        )
        .padding(.bottom, Theme.Spacing.s60)
    }
}

// MARK: - Colours

private extension EliminationCard {
    var eliminationRed: Color {
        Color(hex: "FF453A")
    }

    var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(
                    color: Color(hex: "813E3E"),
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

extension EliminationCard {
    /// Creates an EliminationCard from a LeagueResult.
    static func from(result: LeagueResult) -> EliminationCard {
        let pickedTeamLogo: String?
        if result.pickedHome {
            pickedTeamLogo = result.homeTeamLogo
        } else {
            pickedTeamLogo = result.awayTeamLogo
        }
        return EliminationCard(
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
