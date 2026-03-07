import Foundation

struct Fixture: Identifiable, Codable, Sendable, Equatable {
    let id: Int
    let gameweekId: Int
    let homeTeamId: Int
    let homeTeamName: String
    let homeTeamShort: String
    let awayTeamId: Int
    let awayTeamName: String
    let awayTeamShort: String
    let kickoffAt: Date
    let status: FixtureStatus
    let homeScore: Int?
    let awayScore: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case gameweekId = "gameweek_id"
        case homeTeamId = "home_team_id"
        case homeTeamName = "home_team_name"
        case homeTeamShort = "home_team_short"
        case awayTeamId = "away_team_id"
        case awayTeamName = "away_team_name"
        case awayTeamShort = "away_team_short"
        case kickoffAt = "kickoff_at"
        case status
        case homeScore = "home_score"
        case awayScore = "away_score"
    }

    var hasKickedOff: Bool {
        kickoffAt <= Date()
    }
}

enum FixtureStatus: String, Codable, Sendable {
    case notStarted = "NS"
    case firstHalf = "1H"
    case halfTime = "HT"
    case secondHalf = "2H"
    case fullTime = "FT"
    case postponed = "PST"
    case cancelled = "CANC"
    case abandoned = "ABD"

    var isLive: Bool {
        switch self {
        case .firstHalf, .halfTime, .secondHalf: return true
        default: return false
        }
    }

    var isFinished: Bool {
        self == .fullTime
    }

    var displayLabel: String {
        switch self {
        case .notStarted:  return ""
        case .firstHalf:   return "1H"
        case .halfTime:    return "HT"
        case .secondHalf:  return "2H"
        case .fullTime:    return "FT"
        case .postponed:   return "PST"
        case .cancelled:   return "CANC"
        case .abandoned:   return "ABD"
        }
    }
}
