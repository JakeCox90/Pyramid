import SwiftUI

struct StoryCardView: View {
    let card: StoryCard

    var body: some View {
        switch card {
        case let .title(leagueName, gameweek, aliveCount, totalCount):
            StoryTitleCard(leagueName: leagueName, gameweek: gameweek,
                          aliveCount: aliveCount, totalCount: totalCount)
        case let .headline(headline, body):
            StoryHeadlineCard(headline: headline, narrativeBody: body)
        case let .upset(fixture, eliminationCount):
            StoryUpsetCard(fixture: fixture, eliminationCount: eliminationCount)
        case let .eliminated(players):
            StoryEliminatedCard(players: players)
        case let .massElimination(playerCount):
            StoryMassElimCard(playerCount: playerCount)
        case let .wildcard(player):
            StoryWildcardCard(player: player)
        case let .yourPick(pick):
            StoryYourPickCard(pick: pick)
        case let .standing(players, totalCount, userStatus):
            StoryStandingCard(players: players, totalCount: totalCount, userStatus: userStatus)
        }
    }
}
