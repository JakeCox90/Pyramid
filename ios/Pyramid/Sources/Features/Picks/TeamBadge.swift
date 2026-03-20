import SwiftUI
import UIKit

struct TeamBadge: View {
    let teamName: String
    let logoURL: String?
    let size: CGFloat

    var body: some View {
        if let localImage = Self.localBadge(for: teamName) {
            localImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else if let logoURL, let url = URL(string: logoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                case .failure:
                    fallbackBadge
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    fallbackBadge
                }
            }
        } else {
            fallbackBadge
        }
    }

    private var fallbackBadge: some View {
        Text(teamName.prefix(3).uppercased())
            .font(size > 24 ? Theme.Typography.caption1 : Theme.Typography.caption2)
            .foregroundStyle(Theme.Color.Content.Text.subtle)
            .frame(width: size, height: size)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(Circle())
    }

    // MARK: - Local badge lookup

    private static let assetNameMap: [String: String] = [
        "arsenal": "TeamBadges/Arsenal",
        "aston villa": "TeamBadges/Aston_Villa",
        "bournemouth": "TeamBadges/Bournemouth",
        "afc bournemouth": "TeamBadges/Bournemouth",
        "brentford": "TeamBadges/Brentford",
        "brighton": "TeamBadges/Brighton",
        "brighton & hove albion": "TeamBadges/Brighton",
        "brighton and hove albion": "TeamBadges/Brighton",
        "burnley": "TeamBadges/Burnley",
        "chelsea": "TeamBadges/Chelsea",
        "crystal palace": "TeamBadges/Crystal_Palace",
        "everton": "TeamBadges/Everton",
        "fulham": "TeamBadges/Fulham",
        "ipswich": "TeamBadges/Ipswich_Town",
        "ipswich town": "TeamBadges/Ipswich_Town",
        "leeds": "TeamBadges/Leeds_United",
        "leeds united": "TeamBadges/Leeds_United",
        "leicester": "TeamBadges/Leicester_City",
        "leicester city": "TeamBadges/Leicester_City",
        "liverpool": "TeamBadges/Liverpool",
        "manchester city": "TeamBadges/Manchester_City",
        "man city": "TeamBadges/Manchester_City",
        "manchester united": "TeamBadges/Manchester_United",
        "man united": "TeamBadges/Manchester_United",
        "man utd": "TeamBadges/Manchester_United",
        "newcastle": "TeamBadges/Newcastle_United",
        "newcastle united": "TeamBadges/Newcastle_United",
        "nottingham forest": "TeamBadges/Nottingham_Forest",
        "nott'm forest": "TeamBadges/Nottingham_Forest",
        "southampton": "TeamBadges/Southampton",
        "sunderland": "TeamBadges/Sunderland",
        "tottenham": "TeamBadges/Tottenham_Hotspur",
        "tottenham hotspur": "TeamBadges/Tottenham_Hotspur",
        "spurs": "TeamBadges/Tottenham_Hotspur",
        "west ham": "TeamBadges/West_Ham_United",
        "west ham united": "TeamBadges/West_Ham_United",
        "wolverhampton": "TeamBadges/Wolverhampton",
        "wolverhampton wanderers": "TeamBadges/Wolverhampton",
        "wolves": "TeamBadges/Wolverhampton",
    ]

    static func localBadge(for teamName: String) -> Image? {
        let key = teamName.lowercased().trimmingCharacters(in: .whitespaces)
        guard let assetName = assetNameMap[key] else { return nil }
        let uiImage = UIImage(named: assetName)
        return uiImage.map { Image(uiImage: $0) }
    }
}
