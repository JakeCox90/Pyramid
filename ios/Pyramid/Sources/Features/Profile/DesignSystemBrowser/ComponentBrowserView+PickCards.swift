#if DEBUG
import SwiftUI

// MARK: - Sample Fixture

extension ComponentBrowserView {
    static var samplePickFixture: Fixture {
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
            awayScore: nil
        )
    }
}

// MARK: - Pick Carousel Card

extension ComponentBrowserView {
    var pickCarouselCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(
                title: "MatchCarouselCard"
            )

            ComponentCaption(
                text: "Default (selectable)"
            )
            MatchCarouselCard(
                fixture: Self.samplePickFixture,
                selectedTeamId: nil,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )

            ComponentCaption(
                text: "Team picked"
            )
            MatchCarouselCard(
                fixture: Self.samplePickFixture,
                selectedTeamId: 42,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )

            ComponentCaption(
                text: "With used team"
            )
            MatchCarouselCard(
                fixture: Self.samplePickFixture,
                selectedTeamId: nil,
                usedTeamIds: [42],
                usedTeamRounds: [42: 18],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )

            ComponentCaption(
                text: "Locked"
            )
            MatchCarouselCard(
                fixture: Self.samplePickFixture,
                selectedTeamId: nil,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: true,
                isSubmitting: false,
                onPick: { _, _ in }
            )
        }
    }
}

// MARK: - Pick List Card (FixturePickRow)

extension ComponentBrowserView {
    var pickListCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(
                title: "FixturePickRow"
            )

            ComponentCaption(
                text: "Default (selectable)"
            )
            FixturePickRow(
                fixture: Self.samplePickFixture,
                selectedTeamId: nil,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )

            ComponentCaption(
                text: "Team picked"
            )
            FixturePickRow(
                fixture: Self.samplePickFixture,
                selectedTeamId: 42,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )

            ComponentCaption(
                text: "With used team"
            )
            FixturePickRow(
                fixture: Self.samplePickFixture,
                selectedTeamId: nil,
                usedTeamIds: [42],
                usedTeamRounds: [42: 18],
                isLocked: false,
                isSubmitting: false,
                onPick: { _, _ in }
            )

            ComponentCaption(
                text: "Locked"
            )
            FixturePickRow(
                fixture: Self.samplePickFixture,
                selectedTeamId: nil,
                usedTeamIds: [],
                usedTeamRounds: [:],
                isLocked: true,
                isSubmitting: false,
                onPick: { _, _ in }
            )
        }
    }
}

#endif
