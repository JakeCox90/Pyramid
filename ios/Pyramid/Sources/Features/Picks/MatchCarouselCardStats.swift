import SwiftUI

// Figma: Match Card — Variant=Stats (node 46:4258)
// 352×452, same gradient + stroke as match card
// layout_S4E0N8: 352×452
// fill_YB7865: gradient 225deg #5E4E81→#2D253D over #241E31
// stroke_JCNOZ3: rgba(255,255,255,0.1) 1px
// effect_QOO7CJ: box-shadow 0px 4px 24px rgba(0,0,0,0.25)

struct MatchCarouselCardStats: View {
    let fixture: Fixture
    let stats: MatchStats
    let onBack: () -> Void

    var body: some View {
        ZStack {
            cardBackground
            VStack(spacing: 0) {
                teamHeader
                statsBody
                Spacer(minLength: 0)
                backButton
            }
        }
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(0.25),
            radius: 12, x: 0, y: 4
        )
    }

    // fill_YB7865: gradient 225deg over #241E31
    private var cardBackground: some View {
        ZStack {
            Color(hex: "241E31")
            LinearGradient(
                stops: [
                    .init(
                        color: Color(hex: "5E4E81"),
                        location: 0.0
                    ),
                    .init(
                        color: Color(hex: "2D253D"),
                        location: 0.72
                    ),
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

// MARK: - Team Header

extension MatchCarouselCardStats {
    /// Figma: Frame 54 (46:4261) — x:1 y:26, 350×62
    /// Two half-tint rects + badges (39×39) + team names
    /// style_HJ4JKW: Inter Bold 16 uppercase
    private var teamHeader: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midX = w / 2

            // Half-tint backgrounds
            // layout_RPWUGE: 163×62 at x:0
            // layout_TVYLG9: 163×62 at x:187
            let tintW: CGFloat = (w - 26) / 2
            let tintH: CGFloat = 62

            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 200,
                topTrailingRadius: 200
            )
            .fill(Color(hex: "241E31"))
            .frame(width: tintW, height: tintH)
            .position(x: tintW / 2, y: tintH / 2)

            UnevenRoundedRectangle(
                topLeadingRadius: 200,
                bottomLeadingRadius: 200,
                bottomTrailingRadius: 8,
                topTrailingRadius: 8
            )
            .fill(Color(hex: "241E31"))
            .frame(width: tintW, height: tintH)
            .position(
                x: w - tintW / 2, y: tintH / 2
            )

            // layout_P6GTEI: badge at x:13 y:11, 39×39
            TeamBadge(
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo,
                size: 39
            )
            .position(x: 13 + 19.5, y: 11 + 19.5)

            // layout_8MBI49: badge at x:298 y:11, 39×39
            TeamBadge(
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo,
                size: 39
            )
            .position(x: w - (w - 298) + 19.5, y: 30.5)

            // layout_G1ZFXK: "Arsenal" at x:61 y:21
            Text(fixture.homeTeamShort)
                .font(
                    .system(size: 16, weight: .bold)
                )
                .textCase(.uppercase)
                .foregroundStyle(Color.white)
                .position(x: midX / 2, y: 30)

            // layout_2I61OO: "A. Villa" at x:215 y:21
            Text(fixture.awayTeamShort)
                .font(
                    .system(size: 16, weight: .bold)
                )
                .textCase(.uppercase)
                .foregroundStyle(Color.white)
                .position(x: midX + midX / 2, y: 30)
        }
        .frame(height: 62)
        .padding(.top, 26)
        .padding(.horizontal, 1)
    }
}

// MARK: - Back Button

extension MatchCarouselCardStats {
    /// Figma: Frame 5 (46:4082) — x:12 y:391, 329×44
    /// Single "Back" button, Secondary variant
    /// fill_8I41KE: rgba(255,255,255,0.1)
    /// borderRadius 200px (capsule)
    private var backButton: some View {
        Button(action: onBack) {
            Text("Close")
                .font(Theme.Typography.label01)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 17)
    }
}
