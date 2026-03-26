import SwiftUI

// Figma: Pick Card component (node 7:7935)
// layout_3WWVIL: fill width, fixed height 212
// fill_CRMJ7P: linear-gradient(225deg, rgba(94,78,129,1) 0%,
//              rgba(45,37,61,1) 72%) over #241E31
// stroke_5G2A2W: 1px rgba(255,255,255,0.1)
// border-radius: 24px

struct FixturePickRow: View {
    let fixture: Fixture
    let selectedTeamId: Int?
    let usedTeamIds: Set<Int>
    let usedTeamRounds: [Int: Int]
    let isLocked: Bool
    let isSubmitting: Bool
    var submittingTeamId: Int?
    var celebratedTeamId: Int?
    var showCelebration: Bool = false
    let onPick: (Int, String) -> Void

    @Environment(\.accessibilityReduceMotion)
    var reduceMotion

    var body: some View {
        ZStack {
            cardBackground
            cardContent
        }
        .frame(height: 212)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Theme.Color.Border.light,
                    lineWidth: 1
                )
        )
    }

    // fill_CRMJ7P: gradient 225deg, 0% → 72%
    var cardBackground: some View {
        ZStack {
            Theme.Color.Surface.Background.page
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

    private var cardContent: some View {
        VStack(spacing: 0) {
            matchupArea
            Spacer().frame(height: Theme.Spacing.s60)
            pickButtons
        }
    }
}

// MARK: - Matchup Area

extension FixturePickRow {
    // Badges at y:11, names at y:106, VS at y:65
    var matchupArea: some View {
        ZStack {
            HStack(spacing: 0) {
                homeBadgeSide
                Spacer()
                awayBadgeSide
            }
            .padding(.horizontal, 34)
            .padding(.top, 11)

            vsLabel
                .position(x: 176, y: 72.5)
        }
        .frame(height: 121)
    }

    private var homeBadgeSide: some View {
        let isUsed = usedTeamIds.contains(
            fixture.homeTeamId
        ) && selectedTeamId != fixture.homeTeamId

        return VStack(spacing: 8) {
            // layout_IFTOR2: 76.38 × 74
            TeamBadge(
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo,
                size: 76
            )
            .saturation(isUsed ? 0 : 1)
            .opacity(isUsed ? 0.4 : 1.0)

            teamNameLabel(
                fixture.homeTeamName, isUsed: isUsed
            )
        }
    }

    private var awayBadgeSide: some View {
        let isUsed = usedTeamIds.contains(
            fixture.awayTeamId
        ) && selectedTeamId != fixture.awayTeamId

        return VStack(spacing: 8) {
            // layout_7IOOAX: 74 × 74
            TeamBadge(
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo,
                size: 74
            )
            .saturation(isUsed ? 0 : 1)
            .opacity(isUsed ? 0.4 : 1.0)

            teamNameLabel(
                fixture.awayTeamName, isUsed: isUsed
            )
        }
    }

    // style_U4AW74: Inter Bold 12, uppercase, center
    // fill_2XNJIC: #FFFFFF, opacity 0.4
    private func teamNameLabel(
        _ name: String, isUsed: Bool
    ) -> some View {
        Text(name.uppercased())
            .font(Theme.Typography.overline)
            .foregroundStyle(Theme.Color.Content.Text.disabled)
            .opacity(isUsed ? 0.75 : 1.0)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    // VS circle with vertical divider — matches MatchCarouselCard+Matchup
    var vsLabel: some View {
        ZStack {
            // Vertical divider line behind VS circle
            Rectangle()
                .fill(Theme.Color.Border.default)
                .frame(width: 1, height: 121)

            // VS circle
            ZStack {
                Circle()
                    .fill(Theme.Color.Surface.Background.elevated)
                Circle()
                    .stroke(
                        Theme.Color.Border.default,
                        lineWidth: 1
                    )
                Text("VS")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
            .frame(width: 32, height: 32)
        }
    }
}
