#if DEBUG
import SwiftUI

private var sampleFixture: Fixture {
    Fixture(
        id: 99,
        gameweekId: 20,
        homeTeamId: 42,
        homeTeamName: "Arsenal",
        homeTeamShort: "ARS",
        homeTeamLogo: nil,
        awayTeamId: 66,
        awayTeamName: "Aston Villa",
        awayTeamShort: "AVL",
        awayTeamLogo: nil,
        kickoffAt: Date()
            .addingTimeInterval(86400),
        status: .notStarted,
        homeScore: nil,
        awayScore: nil,
        venue: "Emirates Stadium",
        homeWinProb: 0.55,
        drawProb: 0.25,
        awayWinProb: 0.20
    )
}

struct PickLargeDemo: View {
    var body: some View {
        DemoPageStatic {
            MatchCarouselCard(
                fixture: sampleFixture,
                selectedTeamId: nil,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )
        }
    }
}

struct PickSmallDemo: View {
    var body: some View {
        DemoPageStatic {
            VStack(spacing: Theme.Spacing.s30) {
                FixturePickRow(
                    fixture: sampleFixture,
                    selectedTeamId: nil,
                    usedTeamIds: [],
                    usedTeamRounds: [:],
                    isLocked: false,
                    isSubmitting: false,
                    onPick: { _, _ in }
                )
                FixturePickRow(
                    fixture: sampleFixture,
                    selectedTeamId: 42,
                    usedTeamIds: [],
                    usedTeamRounds: [:],
                    isLocked: false,
                    isSubmitting: false,
                    onPick: { _, _ in }
                )
            }
        }
    }
}
#endif
