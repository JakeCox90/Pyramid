import Foundation

// MARK: - PL Venue Mapping

enum FixtureMetadata {
    /// Stadium name for a given PL home team.
    static func venue(
        forHomeTeam name: String
    ) -> String? {
        venues[name]
    }

    private static let venues: [String: String] = [
        "Arsenal": "Emirates Stadium",
        "Aston Villa": "Villa Park",
        "Bournemouth": "Vitality Stadium",
        "Brentford": "Gtech Community Stadium",
        "Brighton": "Amex Stadium",
        "Brighton & Hove Albion": "Amex Stadium",
        "Chelsea": "Stamford Bridge",
        "Crystal Palace": "Selhurst Park",
        "Everton": "Goodison Park",
        "Fulham": "Craven Cottage",
        "Ipswich": "Portman Road",
        "Ipswich Town": "Portman Road",
        "Leicester": "King Power Stadium",
        "Leicester City": "King Power Stadium",
        "Liverpool": "Anfield",
        "Manchester City": "Etihad Stadium",
        "Manchester United": "Old Trafford",
        "Newcastle": "St James' Park",
        "Newcastle United": "St James' Park",
        "Nottingham Forest": "City Ground",
        "Southampton": "St Mary's Stadium",
        "Tottenham": "Tottenham Hotspur Stadium",
        "Tottenham Hotspur": "Tottenham Hotspur Stadium",
        "West Ham": "London Stadium",
        "West Ham United": "London Stadium",
        "Wolves": "Molineux Stadium",
        "Wolverhampton": "Molineux Stadium",
        "Wolverhampton Wanderers": "Molineux Stadium"
    ]
}
