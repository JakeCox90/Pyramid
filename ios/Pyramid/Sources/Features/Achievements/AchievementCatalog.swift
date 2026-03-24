import Foundation

struct BadgeDefinition {
    let id: String
    let name: String
    let description: String
    let icon: String
    let track: String?
    let tier: Int?
    let style: FlagVariant
}

enum AchievementCatalog {
    static let survivalStreak1 = BadgeDefinition(
        id: "survival_streak_1", name: "Survivor",
        description: "Survive 3 consecutive gameweeks in a single league",
        icon: "shield.fill", track: "survival_streak", tier: 1, style: .success)
    static let survivalStreak2 = BadgeDefinition(
        id: "survival_streak_2", name: "Iron Wall",
        description: "Survive 5 consecutive gameweeks in a single league",
        icon: "shield.fill", track: "survival_streak", tier: 2, style: .success)
    static let survivalStreak3 = BadgeDefinition(
        id: "survival_streak_3", name: "Untouchable",
        description: "Survive 10 consecutive gameweeks in a single league",
        icon: "shield.fill", track: "survival_streak", tier: 3, style: .success)

    static let champion1 = BadgeDefinition(
        id: "champion_1", name: "Champion",
        description: "Win your first league",
        icon: "trophy.fill", track: "champion", tier: 1, style: .warning)
    static let champion2 = BadgeDefinition(
        id: "champion_2", name: "Dynasty",
        description: "Win 3 leagues",
        icon: "trophy.fill", track: "champion", tier: 2, style: .warning)
    static let champion3 = BadgeDefinition(
        id: "champion_3", name: "Legend",
        description: "Win 5 leagues",
        icon: "trophy.fill", track: "champion", tier: 3, style: .warning)

    static let veteran1 = BadgeDefinition(
        id: "veteran_1", name: "Seasoned",
        description: "Survive 25 total gameweeks",
        icon: "star.fill", track: "veteran", tier: 1, style: .success)
    static let veteran2 = BadgeDefinition(
        id: "veteran_2", name: "Veteran",
        description: "Survive 50 total gameweeks",
        icon: "star.fill", track: "veteran", tier: 2, style: .success)
    static let veteran3 = BadgeDefinition(
        id: "veteran_3", name: "Centurion",
        description: "Survive 100 total gameweeks",
        icon: "star.fill", track: "veteran", tier: 3, style: .success)

    static let longshot1 = BadgeDefinition(
        id: "longshot_1", name: "Longshot I",
        description: "Win 3 picks backing an underdog (<30% win probability)",
        icon: "target", track: "longshot", tier: 1, style: .warning)
    static let longshot2 = BadgeDefinition(
        id: "longshot_2", name: "Longshot II",
        description: "Win 5 underdog picks",
        icon: "target", track: "longshot", tier: 2, style: .warning)
    static let longshot3 = BadgeDefinition(
        id: "longshot_3", name: "Longshot III",
        description: "Win 10 underdog picks",
        icon: "target", track: "longshot", tier: 3, style: .warning)

    static let againstTheOdds = BadgeDefinition(
        id: "against_the_odds", name: "Against the Odds",
        description: "Survive a gameweek where 50%+ of your league was eliminated",
        icon: "bolt.shield.fill", track: nil, tier: nil, style: .success)
    static let landslide = BadgeDefinition(
        id: "landslide", name: "Landslide",
        description: "Your picked team wins by 4+ goals",
        icon: "flame.fill", track: nil, tier: nil, style: .warning)
    static let lastOneStanding = BadgeDefinition(
        id: "last_one_standing", name: "Last One Standing",
        description: "Be the sole survivor when all others are eliminated",
        icon: "person.fill.checkmark", track: nil, tier: nil, style: .success)
    static let giantKiller = BadgeDefinition(
        id: "giant_killer", name: "Giant Killer",
        description: "Survive by picking an underdog with <30% win probability",
        icon: "figure.fencing", track: nil, tier: nil, style: .warning)
    static let nervesOfSteel = BadgeDefinition(
        id: "nerves_of_steel", name: "Nerves of Steel",
        description: "Your pick wins with a goal in the 85th minute or later",
        icon: "timer", track: nil, tier: nil, style: .success)
    static let phoenix = BadgeDefinition(
        id: "phoenix", name: "Phoenix",
        description: "Get eliminated, then win a different league",
        icon: "bird.fill", track: nil, tier: nil, style: .warning)
    static let fullHouse = BadgeDefinition(
        id: "full_house", name: "Full House",
        description: "Pick every gameweek of a complete round without missing a deadline",
        icon: "checkmark.seal.fill", track: nil, tier: nil, style: .success)
    static let icarus = BadgeDefinition(
        id: "icarus", name: "Icarus",
        description: "Survive 5+ gameweeks in a row, then get eliminated",
        icon: "sun.max.fill", track: nil, tier: nil, style: .neutral)

    static let allBadges: [BadgeDefinition] = [
        survivalStreak1, survivalStreak2, survivalStreak3,
        champion1, champion2, champion3,
        veteran1, veteran2, veteran3,
        longshot1, longshot2, longshot3,
        againstTheOdds, landslide, lastOneStanding,
        giantKiller, nervesOfSteel, phoenix, fullHouse, icarus
    ]

    static let tracks: [(name: String, key: String)] = [
        ("Survival Streak", "survival_streak"),
        ("Champion", "champion"),
        ("Veteran", "veteran"),
        ("Longshot", "longshot")
    ]

    static func badge(for id: String) -> BadgeDefinition? {
        allBadges.first { $0.id == id }
    }
}
