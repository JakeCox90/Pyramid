import SwiftUI

// Figma: Match Carousel Card (node 32:4449)
// layout_4M5D1P: 352×452px
// fill_255PQ5: linear-gradient(225deg, rgba(94,78,129,1) 0%,
//              rgba(45,37,61,1) 72%) over #241E31
// stroke_6Z17SD: 1px rgba(255,255,255,0.1), border-radius 24px
// effect_L4A909: box-shadow 0px 4px 24px rgba(0,0,0,0.25)

struct MatchCarouselCard: View {
    let fixture: Fixture
    let selectedTeamId: Int?
    let usedTeamIds: Set<Int>
    let isLocked: Bool
    let isSubmitting: Bool
    var submittingTeamId: Int?
    let onPick: (Int, String) -> Void

    var body: some View {
        ZStack {
            cardBackground
            cardOverlay
        }
        .frame(height: 500)
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

    // fill_255PQ5: gradient 225deg, stops 0% → 72%
    private var cardBackground: some View {
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

    private var cardOverlay: some View {
        VStack(spacing: 0) {
            matchupSection
                .frame(height: 280)
            Spacer(minLength: 0)
            fixtureDetails
            pickButtons
                .padding(.horizontal, 12)
                .padding(.bottom, 17)
        }
    }

    /// Top section: badges, divider, VS, team names
    private var matchupSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midX = w / 2
            let quarterX = w / 4

            // Half-tint backgrounds
            halfTintLayer(
                width: w, midX: midX
            )

            // Vertical divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 217)
                .position(x: midX, y: 108.5)

            // Badges
            TeamBadge(
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo,
                size: 76
            )
            .opacity(homeIsUsed ? 0.2 : 1.0)
            .position(x: quarterX, y: 100)

            TeamBadge(
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo,
                size: 74
            )
            .opacity(awayIsUsed ? 0.2 : 1.0)
            .position(
                x: w - quarterX, y: 100
            )

            // VS circle
            vsCircleView
                .position(x: midX, y: 200)

            // Team names
            Text(fixture.homeTeamShort)
                .font(Theme.Typography.h3)
                .foregroundStyle(Color.white)
                .opacity(homeIsUsed ? 0.2 : 1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: w / 2 - 30)
                .position(x: quarterX, y: 250)

            Text(fixture.awayTeamShort)
                .font(Theme.Typography.h3)
                .foregroundStyle(Color.white)
                .opacity(awayIsUsed ? 0.2 : 1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: w / 2 - 30)
                .position(
                    x: w - quarterX, y: 250
                )
        }
    }

    private func halfTintLayer(
        width w: CGFloat,
        midX: CGFloat
    ) -> some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 200,
                topTrailingRadius: 200
            )
            .fill(Color(hex: "241E31"))
            .frame(
                width: midX - 10,
                height: 152
            )
            .position(
                x: (midX - 10) / 2,
                y: 100
            )

            UnevenRoundedRectangle(
                topLeadingRadius: 200,
                bottomLeadingRadius: 200,
                bottomTrailingRadius: 8,
                topTrailingRadius: 8
            )
            .fill(Color(hex: "241E31"))
            .frame(
                width: midX - 10,
                height: 152
            )
            .position(
                x: w - (midX - 10) / 2,
                y: 100
            )
        }
    }

    private var vsCircleView: some View {
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

    @ViewBuilder private var vsText: some View {
        if fixture.status.isLive
            || fixture.status.isFinished,
            let home = fixture.homeScore,
            let away = fixture.awayScore {
            Text("\(home) - \(away)")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .monospacedDigit()
        } else {
            Text("VS")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
        }
    }

    private var fixtureDetails: some View {
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
            .textCase(.uppercase)
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

    var homeIsUsed: Bool {
        usedTeamIds.contains(fixture.homeTeamId)
            && selectedTeamId != fixture.homeTeamId
    }

    var awayIsUsed: Bool {
        usedTeamIds.contains(fixture.awayTeamId)
            && selectedTeamId != fixture.awayTeamId
    }
}
