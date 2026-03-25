import Foundation

enum StoryCard: Identifiable {
    case title(leagueName: String, gameweek: Int, aliveCount: Int, totalCount: Int)
    case headline(headline: String, body: String)
    case upset(fixture: Fixture, eliminationCount: Int)
    case eliminated(players: [EliminatedPlayer])
    case massElimination(playerCount: Int)
    case wildcard(player: WildcardPlayer)
    case yourPick(pick: YourPickResult)
    case standing(players: [StandingPlayer], totalCount: Int, userStatus: UserStoryStatus)

    var id: String {
        switch self {
        case .title: return "title"
        case .headline: return "headline"
        case .upset: return "upset"
        case .eliminated: return "eliminated"
        case .massElimination: return "mass-elim"
        case .wildcard: return "wildcard"
        case .yourPick: return "your-pick"
        case .standing: return "standing"
        }
    }
}

enum UserStoryStatus {
    case survived
    case eliminated
    case winner
    case missedDeadline
    case voidSurvived
}

struct EliminatedPlayer: Identifiable, Equatable {
    let id: String // userId
    let displayName: String
    let teamName: String
    let result: String
    let isAutoEliminated: Bool
}

struct WildcardPlayer: Equatable {
    let displayName: String
    let teamName: String
    let result: String
    let survived: Bool
}

struct YourPickResult: Equatable {
    let teamName: String?
    let teamId: Int?
    let result: String?
    let status: UserStoryStatus
}

struct StandingPlayer: Identifiable, Equatable {
    let id: String // userId
    let displayName: String
    let isCurrentUser: Bool
}
