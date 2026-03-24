import SwiftUI

// MARK: - Matchup Section

extension MatchCarouselCard {
    /// Top section: badges, divider, VS, team names
    var matchupSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midX = w / 2
            let quarterX = w / 4

            // Half-tint backgrounds
            halfTintLayer(
                width: w, midX: midX
            )

            // Top divider: y:0 → y:217 (above VS circle)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 217)
                .position(x: midX, y: 108.5)

            // Bottom divider: from VS circle bottom (y:257)
            // to bottom of matchup section (y:280)
            let vsBottom: CGFloat = 257
            let segmentH = geo.size.height - vsBottom
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: segmentH)
                .position(
                    x: midX,
                    y: vsBottom + segmentH / 2
                )

            // Badges vertically centred within the
            // half-tint semicircles (tintY = 51 + 152/2 = 127)
            TeamBadge(
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo,
                size: 76
            )
            .saturation(homeIsUsed ? 0 : 1)
            .opacity(homeIsUsed ? 0.4 : 1.0)
            .position(x: quarterX, y: 127)

            TeamBadge(
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo,
                size: 74
            )
            .saturation(awayIsUsed ? 0 : 1)
            .opacity(awayIsUsed ? 0.4 : 1.0)
            .position(
                x: w - quarterX, y: 127
            )

            // Figma: VS circle 40×40 at x:156 y:217
            vsCircleView
                .position(x: midX, y: 237)

            // Team names aligned with VS circle center
            Text(fixture.homeTeamShort)
                .font(Theme.Typography.h3)
                .foregroundStyle(Color.white)
                .opacity(homeIsUsed ? 0.4 : 1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: w / 2 - 30)
                .position(x: quarterX, y: 237)

            Text(fixture.awayTeamShort)
                .font(Theme.Typography.h3)
                .foregroundStyle(Color.white)
                .opacity(awayIsUsed ? 0.4 : 1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: w / 2 - 30)
                .position(
                    x: w - quarterX, y: 237
                )
        }
    }

    /// Two half-tint rects behind each badge.
    /// Outer edges (touching card edge) have 0 radius
    /// so they sit flush; inner edges use 200 radius.
    func halfTintLayer(
        width w: CGFloat,
        midX: CGFloat
    ) -> some View {
        let tintW = (w - 52) / 2
        let tintH: CGFloat = 152
        let tintY: CGFloat = 51 + tintH / 2

        return ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 200,
                topTrailingRadius: 200
            )
            .fill(Color(hex: "241E31"))
            .frame(width: tintW, height: tintH)
            .position(x: tintW / 2, y: tintY)

            UnevenRoundedRectangle(
                topLeadingRadius: 200,
                bottomLeadingRadius: 200,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(Color(hex: "241E31"))
            .frame(width: tintW, height: tintH)
            .position(
                x: w - tintW / 2, y: tintY
            )
        }
    }

    var vsCircleView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "3D3354"))
            Circle()
                .stroke(
                    Color.white.opacity(0.2),
                    lineWidth: 1
                )
            vsText
        }
        .frame(width: 40, height: 40)
    }

    var vsText: some View {
        Text("VS")
            .font(Theme.Typography.overline)
            .foregroundStyle(Color.white)
    }

    var fixtureDetails: some View {
        VStack(spacing: 3) {
            if let venue = FixtureMetadata.venue(
                forHomeTeam: fixture.homeTeamName
            ) {
                Text(venue)
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Color.white.opacity(0.5)
                    )
            }
            Text(
                fixture.kickoffAt,
                format: .dateTime
                    .weekday(.abbreviated)
                    .day(.defaultDigits)
                    .month(.abbreviated)
                    .hour(.defaultDigits(
                        amPM: .abbreviated
                    ))
                    .minute(.twoDigits)
            )
            .font(Theme.Typography.label01)
            .foregroundStyle(
                Color.white.opacity(0.4)
            )
            Text(FixtureMetadata.broadcastNote)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Color.white.opacity(0.3)
                )
        }
        .padding(.bottom, 12)
    }
}
