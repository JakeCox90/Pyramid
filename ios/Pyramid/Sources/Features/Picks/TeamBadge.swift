import SwiftUI

struct TeamBadge: View {
    let logoURL: String?
    let shortName: String
    let size: CGFloat

    var body: some View {
        if let logoURL, let url = URL(string: logoURL) {
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
        Text(shortName)
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Color.Content.Text.default)
            .frame(width: size, height: size)
    }
}
