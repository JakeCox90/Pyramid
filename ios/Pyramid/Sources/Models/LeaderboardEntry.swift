import Foundation

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let rank: Int
    let userId: String
    let displayName: String?
    let avatarUrl: String?
    let survivalRatePct: Int
    let longestStreak: Int
    let wins: Int
    let totalPicks: Int

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case survivalRatePct = "survival_rate_pct"
        case longestStreak = "longest_streak"
        case wins
        case totalPicks = "total_picks"
    }
}
