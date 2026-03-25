#if DEBUG
import SwiftUI

// MARK: - MatchCard Variants

extension ComponentBrowserView {
    var matchCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "MatchCard")

            ComponentCaption(
                text: "Pre-Game (unlocked)"
            )
            MatchCard(
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                venue: "Emirates Stadium",
                kickoff: Calendar.current.date(
                    bySettingHour: 15,
                    minute: 0,
                    second: 0,
                    of: Date()
                        .addingTimeInterval(86400)
                ),
                phase: .preMatch,
                buttonTitle: "CHANGE PICK",
                onButtonTap: {}
            )

            ComponentCaption(
                text: "Pre-Game (locked)"
            )
            MatchCard(
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                venue: "Emirates Stadium",
                kickoff: Calendar.current.date(
                    bySettingHour: 15,
                    minute: 0,
                    second: 0,
                    of: Date()
                ),
                phase: .preMatch,
                isLocked: true
            )

            ComponentCaption(
                text: "In Progress (0-0)"
            )
            MatchCard(
                pickedTeamName: "Liverpool",
                pickedTeamLogo: nil,
                opponentName: "Chelsea",
                homeTeamName: "Liverpool",
                homeScore: 0,
                awayScore: 0,
                phase: .live
            )

            ComponentCaption(
                text: "In Progress (2-1)"
            )
            MatchCard(
                pickedTeamName: "Liverpool",
                pickedTeamLogo: nil,
                opponentName: "Chelsea",
                homeTeamName: "Liverpool",
                homeScore: 2,
                awayScore: 1,
                phase: .live
            )

            ComponentCaption(
                text: "Full Time — Survived"
            )
            MatchCard(
                pickedTeamName: "Man City",
                pickedTeamLogo: nil,
                opponentName: "Tottenham",
                homeTeamName: "Manchester City",
                homeScore: 3,
                awayScore: 0,
                phase: .finished,
                survived: true,
                isLocked: true
            )

            ComponentCaption(
                text: "Full Time — Eliminated"
            )
            MatchCard(
                pickedTeamName: "Man City",
                pickedTeamLogo: nil,
                opponentName: "Tottenham",
                homeTeamName: "Manchester City",
                homeScore: 1,
                awayScore: 2,
                phase: .finished,
                survived: false,
                isLocked: true
            )

            ComponentCaption(
                text: "Full Time — Pending"
            )
            MatchCard(
                pickedTeamName: "Man City",
                pickedTeamLogo: nil,
                opponentName: "Tottenham",
                homeTeamName: "Manchester City",
                homeScore: 1,
                awayScore: 1,
                phase: .finished,
                isLocked: true
            )

            ComponentCaption(
                text: "Empty (no pick)"
            )
            MatchCard.empty(
                isLocked: false,
                onMakePick: {}
            )

            ComponentCaption(
                text: "Empty (locked)"
            )
            MatchCard.empty(isLocked: true)
        }
    }
}

// MARK: - ResultCard

extension ComponentBrowserView {
    var resultCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "ResultCard")

            ComponentCaption(text: "Survived")
            ResultCard(
                homeTeamName: "Liverpool",
                homeTeamShort: "LIV",
                homeTeamLogo: nil,
                awayTeamName: "Everton",
                awayTeamShort: "EVE",
                awayTeamLogo: nil,
                homeScore: 2,
                awayScore: 1,
                pickedHome: true,
                result: .survived
            )

            ComponentCaption(text: "Eliminated")
            ResultCard(
                homeTeamName: "Arsenal",
                homeTeamShort: "ARS",
                homeTeamLogo: nil,
                awayTeamName: "Chelsea",
                awayTeamShort: "CHE",
                awayTeamLogo: nil,
                homeScore: 0,
                awayScore: 2,
                pickedHome: true,
                result: .eliminated
            )
        }
    }
}

// MARK: - EliminationCard

extension ComponentBrowserView {
    var eliminationCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(
                title: "EliminationCard"
            )

            ComponentCaption(
                text: "Home team picked (lost)"
            )
            EliminationCard(
                leagueName: "Sunday League",
                gameweekName: "Gameweek 29",
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                homeTeamShort: "ARS",
                homeTeamLogo: nil,
                awayTeamName: "Aston Villa",
                awayTeamShort: "AVL",
                awayTeamLogo: nil,
                homeScore: 0,
                awayScore: 2,
                pickedHome: true
            )

            ComponentCaption(
                text: "Away team picked (lost)"
            )
            EliminationCard(
                leagueName: "Office Crew",
                gameweekName: "Gameweek 29",
                pickedTeamName: "Chelsea",
                pickedTeamLogo: nil,
                opponentName: "Liverpool",
                homeTeamName: "Liverpool",
                homeTeamShort: "LIV",
                homeTeamLogo: nil,
                awayTeamName: "Chelsea",
                awayTeamShort: "CHE",
                awayTeamLogo: nil,
                homeScore: 3,
                awayScore: 1,
                pickedHome: false
            )
        }
    }
}

// MARK: - StatsCard

extension ComponentBrowserView {
    var statsCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(
                title: "MatchCarouselCardStats"
            )

            ComponentCaption(
                text: "Stats (card back)"
            )
            MatchCarouselCardStats(
                fixture: Fixture(
                    id: 1,
                    gameweekId: 20,
                    homeTeamId: 42,
                    homeTeamName: "Arsenal",
                    homeTeamShort: "ARS",
                    homeTeamLogo: nil,
                    awayTeamId: 66,
                    awayTeamName: "Aston Villa",
                    awayTeamShort: "A. Villa",
                    awayTeamLogo: nil,
                    kickoffAt: Date()
                        .addingTimeInterval(86400),
                    status: .notStarted,
                    homeScore: nil,
                    awayScore: nil
                ),
                stats: .placeholder,
                onBack: {}
            )
        }
    }
}

#endif
