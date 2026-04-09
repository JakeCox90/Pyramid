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
    let usedTeamRounds: [Int: Int]
    let isLocked: Bool
    let isSubmitting: Bool
    var submittingTeamId: Int?
    let onPick: (Int, String) -> Void
    var onStats: (() -> Void)?

    var body: some View {
        ZStack {
            cardBackground
            cardOverlay
        }
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Theme.Color.Border.light,
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(0.25),
            radius: 12, x: 0, y: 4
        )
    }

    // fill_255PQ5: gradient 225deg, stops 0% → 72% — see MatchCardBackground
    private var cardBackground: some View {
        MatchCardBackground()
    }

    private var cardOverlay: some View {
        VStack(spacing: 0) {
            matchupSection
                .frame(height: 280)
            bottomDivider
            fixtureDetails
            pickButtons
                .padding(.horizontal, 12)
                .padding(.bottom, 17)
        }
    }

    /// Dynamic vertical divider that fills the space
    /// between the matchup section and fixture details
    private var bottomDivider: some View {
        Rectangle()
            .fill(Theme.Color.Border.default)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .padding(.bottom, 8)
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
