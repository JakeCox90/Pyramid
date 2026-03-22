import SwiftUI

// MARK: - Half-Tint Backgrounds

extension MatchCarouselCard {
    // layout_6LTY6Y: left 151×152 at (1, 51), fill #241E31
    // layout_TM9M0C: right 150×152 at (201, 51), fill #241E31
    // borderRadius: 8px 200px 200px 8px (rounded towards center)
    var halfTints: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 200,
                topTrailingRadius: 200
            )
            .fill(Color(hex: "241E31"))
            .frame(width: 151, height: 152)
            .position(x: 76.5, y: 127)

            UnevenRoundedRectangle(
                topLeadingRadius: 200,
                bottomLeadingRadius: 200,
                bottomTrailingRadius: 8,
                topTrailingRadius: 8
            )
            .fill(Color(hex: "241E31"))
            .frame(width: 150, height: 152)
            .position(x: 276, y: 127)
        }
    }
}

// MARK: - Vertical Dividers

extension MatchCarouselCard {
    // stroke_MW2XXR: rgba(255,255,255,0.2), 1px
    // Top segment: y:0, height 217
    // Bottom segment: y:257, height 63
    var verticalDividers: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 217)
                .position(x: 176, y: 108.5)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 63)
                .position(x: 176, y: 288.5)
        }
    }
}

// MARK: - Team Badges

extension MatchCarouselCard {
    // layout_ZB7T35: home badge 76px at (38, 94)
    // layout_DY4D3L: away badge 74px at (241, 93)
    var badges: some View {
        ZStack {
            TeamBadge(
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo,
                size: 76
            )
            .opacity(homeIsUsed ? 0.2 : 1.0)
            .position(x: 76, y: 132)

            TeamBadge(
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo,
                size: 74
            )
            .opacity(awayIsUsed ? 0.2 : 1.0)
            .position(x: 278, y: 130)
        }
    }
}

// MARK: - VS Circle

extension MatchCarouselCard {
    // layout_AM2QH8: 40×40 at (156, 217)
    // fill_2OR28G: #3D3354
    // stroke_MW2XXR: rgba(255,255,255,0.2), 1px
    var vsCircle: some View {
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
        .position(x: 176, y: 237)
    }

    // style_GX62RA: Inter Bold 12, uppercase, center
    @ViewBuilder private var vsText: some View {
        if fixture.status.isLive
            || fixture.status.isFinished,
            let home = fixture.homeScore,
            let away = fixture.awayScore {
            Text("\(home) - \(away)")
                .font(
                    Font.custom(
                        "Inter-SemiBold", size: 14
                    )
                )
                .foregroundStyle(Color.white)
                .monospacedDigit()
        } else {
            Text("VS")
                .font(
                    Font.custom(
                        "Inter-Bold", size: 12
                    )
                )
                .foregroundStyle(Color.white)
        }
    }
}

// MARK: - Team Names

extension MatchCarouselCard {
    // style_UJD87U: Inter Bold 24, center
    // Home: (29.42, 229), Away: (228, 229)
    var teamNames: some View {
        ZStack {
            Text(fixture.homeTeamShort.uppercased())
                .font(
                    Font.custom("Inter-Bold", size: 24)
                )
                .foregroundStyle(Color.white)
                .opacity(homeIsUsed ? 0.2 : 1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 150)
                .position(x: 88, y: 243.5)

            Text(fixture.awayTeamShort.uppercased())
                .font(
                    Font.custom("Inter-Bold", size: 24)
                )
                .foregroundStyle(Color.white)
                .opacity(awayIsUsed ? 0.2 : 1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 150)
                .position(x: 264, y: 243.5)
        }
    }
}
