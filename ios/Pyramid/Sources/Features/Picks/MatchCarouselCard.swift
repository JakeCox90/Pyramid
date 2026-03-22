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
        .frame(width: 352, height: 452)
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
        ZStack {
            halfTints
            verticalDividers
            badges
            vsCircle
            teamNames
            VStack {
                Spacer()
                pickButtons
                    .padding(.horizontal, 12)
                    .padding(.bottom, 17)
            }
        }
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
