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
                    Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }

    // fill_CRMJ7P: gradient 225deg, 0% → 72%
    var cardBackground: some View {
        ZStack {
            Color(hex: "241E31")
            LinearGradient(
                stops: [
                    .init(
                        color: Color(
                            red: 94 / 255,
                            green: 78 / 255,
                            blue: 129 / 255
                        ),
                        location: 0.0
                    ),
                    .init(
                        color: Color(
                            red: 45 / 255,
                            green: 37 / 255,
                            blue: 61 / 255
                        ),
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
            pickTeamDivider
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
            .opacity(isUsed ? 0.2 : 1.0)

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
            .opacity(isUsed ? 0.2 : 1.0)

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
            .foregroundStyle(Color.white)
            .opacity(isUsed ? 0.2 : 0.4)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    // layout_38AZYE: 17×15 at x:167.21, y:65
    // style_U4AW74: Inter Bold 12, uppercase
    var vsLabel: some View {
        Group {
            if fixture.status.isLive
                || fixture.status.isFinished,
               let home = fixture.homeScore,
               let away = fixture.awayScore {
                Text("\(home) - \(away)")
                    .font(Theme.Typography.h3)
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
            } else {
                Text("VS")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Color.white)
            }
        }
    }
}

// MARK: - Pick Team Divider

extension FixturePickRow {
    // layout_KGNZ8S: x:6, y:127, width:340, height:15
    // Divider lines: stroke_53XB8X = rgba(255,255,255,0.2), 1px
    // Text: style_U4AW74 = Inter Bold 12, uppercase
    var pickTeamDivider: some View {
        HStack(spacing: 0) {
            dividerLine
            Text("PICK TEAM")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )
                .padding(.horizontal, 12)
            dividerLine
        }
        .padding(.horizontal, 6)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(height: 1)
    }
}
