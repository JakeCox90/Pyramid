import SwiftUI

// MARK: - Hero Match Card

extension HomeView {
    @ViewBuilder
    func matchCard(
        _ context: LivePickContext
    ) -> some View {
        let fixture = context.fixture
        let pickedHome = context.pick.teamId
            == fixture.homeTeamId
        let pickedTeam = pickedHome
            ? fixture.homeTeamName
            : fixture.awayTeamName
        let opponent = pickedHome
            ? fixture.awayTeamName
            : fixture.homeTeamName
        let badgeLogo = pickedHome
            ? fixture.homeTeamLogo
            : fixture.awayTeamLogo

        let phase = matchCardPhase(fixture)
        let showScores = phase == .live || phase == .finished

        MatchCard(
            pickedTeamName: pickedTeam,
            pickedTeamLogo: badgeLogo,
            opponentName: opponent,
            homeTeamName: fixture.homeTeamName,
            venue: fixture.venue
                ?? FixtureMetadata.venue(
                    forHomeTeam: fixture.homeTeamName
                ),
            kickoff: fixture.kickoffAt,
            homeScore: showScores ? fixture.homeScore : nil,
            awayScore: showScores ? fixture.awayScore : nil,
            phase: phase,
            survived: phase == .finished
                ? context.isSurviving : nil,
            isLocked: viewModel.isGameweekLocked,
            buttonTitle: "CHANGE PICK",
            onButtonTap: { showPicks = true }
        )
    }

    @ViewBuilder
    func matchCardEmpty() -> some View {
        MatchCard.empty(
            isLocked: viewModel.isGameweekLocked,
            onMakePick: { showPicks = true }
        )
    }

    /// Derives the visual phase for the match card.
    /// The gameweek phase acts as a ceiling: if the gameweek
    /// hasn't started, the card is always pre-match regardless
    /// of stale fixture data from the API.
    func matchCardPhase(
        _ fixture: Fixture
    ) -> MatchCard.Phase {
        switch viewModel.gameweekPhase {
        case .upcoming, .unknown:
            // GW hasn't started — always pre-match
            return .preMatch
        case .inProgress:
            if fixture.status.isLive { return .live }
            if fixture.status.isFinished { return .finished }
            return .preMatch
        case .finished:
            if fixture.status.isLive { return .live }
            return .finished
        }
    }
}
