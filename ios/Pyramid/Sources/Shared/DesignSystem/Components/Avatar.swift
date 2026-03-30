import SwiftUI

// MARK: - Avatar

enum AvatarSize {
    case small, medium, large

    var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 64
        }
    }

    var font: Font {
        switch self {
        case .small: return Theme.Typography.overline
        case .medium: return Theme.Typography.caption
        case .large: return Theme.Typography.subhead
        }
    }
}

struct Avatar: View {
    let name: String
    let imageURL: String?
    let size: AvatarSize

    init(
        name: String,
        imageURL: String? = nil,
        size: AvatarSize = .medium
    ) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
    }

    var body: some View {
        if let imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: size.dimension,
                            height: size.dimension
                        )
                        .clipShape(Circle())
                case .failure:
                    initialsView
                case .empty:
                    ProgressView()
                        .frame(
                            width: size.dimension,
                            height: size.dimension
                        )
                @unknown default:
                    initialsView
                }
            }
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        Text(initials)
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundStyle(
                Theme.Color.Content.Text.contrast
            )
            .frame(
                width: size.dimension,
                height: size.dimension
            )
            .background(initialsColor)
            .clipShape(Circle())
    }

    /// Derives display initials from a name (e.g. "Jake Cox" → "JC").
    /// Shared so other components can match Avatar's initials logic.
    static func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(
                parts[0].prefix(1)
                    + parts[1].prefix(1)
            ).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var initials: String {
        Self.initials(for: name)
    }

    private var initialsColor: Color {
        let colors: [Color] = [
            Theme.Color.Primary.resting,
            Theme.Color.Status.Info.resting,
            Theme.Color.Status.Success.resting,
            Theme.Color.Status.Warning.resting
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}
