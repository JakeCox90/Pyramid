import SwiftUI

struct ResultCard: View {
    let homeTeamName: String
    let homeTeamShort: String
    let homeTeamLogo: String?
    let awayTeamName: String
    let awayTeamShort: String
    let awayTeamLogo: String?
    let homeScore: Int
    let awayScore: Int
    var pickedHome: Bool?
    var result: PickResult?

    var body: some View {
        HStack(spacing: 0) {
            homeSide
            scoreCenter
            awaySide
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(height: 93)
        .background(cardGradient)
        .clipShape(
            RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    Theme.Color.Border.subtle,
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(0.2),
            radius: 8, x: 0, y: 4
        )
    }
}

// MARK: - Subviews

private extension ResultCard {
    var homeSide: some View {
        HStack(spacing: Theme.Spacing.s20) {
            TeamBadge(
                teamName: homeTeamName,
                logoURL: homeTeamLogo,
                size: 36
            )
            Text(homeTeamShort)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    var scoreCenter: some View {
        HStack(spacing: Theme.Spacing.s10) {
            resultIcon(isHome: true)
            Text("\(homeScore)")
                .font(Theme.Typography.h2)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .monospacedDigit()
            Text("\u{2013}")
                .font(Theme.Typography.h3)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
            Text("\(awayScore)")
                .font(Theme.Typography.h2)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .monospacedDigit()
            resultIcon(isHome: false)
        }
    }

    var awaySide: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Spacer()
            Text(awayTeamShort)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.default)
            TeamBadge(
                teamName: awayTeamName,
                logoURL: awayTeamLogo,
                size: 36
            )
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    func resultIcon(isHome: Bool) -> some View {
        let picked = pickedHome == isHome
        if picked && result == .survived {
            Image(
                systemName: "checkmark.circle.fill"
            )
            .font(.system(size: 14))
            .foregroundStyle(Theme.Color.Match.winIndicator)
        } else if picked && result == .eliminated {
            Image(
                systemName: "xmark.circle.fill"
            )
            .font(.system(size: 14))
            .foregroundStyle(
                Theme.Color.Status.Error.resting
            )
        } else {
            EmptyView()
        }
    }

    var cardGradient: some View {
        LinearGradient(
            stops: [
                .init(
                    color: Theme.Color.Match.Gradient.purpleStart,
                    location: 0.0
                ),
                .init(
                    color: Theme.Color.Match.Gradient.purpleEnd,
                    location: 0.72
                )
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}
