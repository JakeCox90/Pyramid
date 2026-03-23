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
                    Color.white.opacity(0.1),
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
                .foregroundStyle(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    var scoreCenter: some View {
        HStack(spacing: Theme.Spacing.s10) {
            resultIcon(isHome: true)
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
            resultIcon(isHome: false)
        }
    }

    var awaySide: some View {
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

    @ViewBuilder
    func resultIcon(isHome: Bool) -> some View {
        let picked = pickedHome == isHome
        if picked && result == .survived {
            Image(
                systemName: "checkmark.circle.fill"
            )
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "6CCE78"))
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
                    color: Color(hex: "5E4E81"),
                    location: 0.0
                ),
                .init(
                    color: Color(hex: "2D253D"),
                    location: 0.72
                )
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}
