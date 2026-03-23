#if DEBUG
import SwiftUI

// MARK: - Game Tab

extension ComponentBrowserView {
    var gameContent: some View {
        Group {
            leagueCardSection
            playersRemainingSection
        }
    }
}

// MARK: - League Card (Game tab)

extension ComponentBrowserView {
    var leagueCardSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "LeagueCard")

            LeagueCard(
                leagueName: "Sunday League",
                memberCount: 12,
                gameweek: 28,
                pickStatus: .survived
            )
            LeagueCard(
                leagueName: "Office Crew",
                memberCount: 8,
                gameweek: 28,
                pickStatus: .eliminated
            )
        }
    }
}

// MARK: - PlayersRemainingCard (Game tab)

extension ComponentBrowserView {
    var playersRemainingSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(
                title: "PlayersRemainingCard"
            )

            PlayersRemainingCard(
                remaining: "8/12"
            )

            ComponentCaption(
                text: "With action button"
            )
            PlayersRemainingCard(
                remaining: "5/10",
                onSeeResults: {}
            )
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

// MARK: - Stats Card (Carousel Back)

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
