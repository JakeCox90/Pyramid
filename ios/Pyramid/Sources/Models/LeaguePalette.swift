import SwiftUI

/// Maps a league's `colorPalette` key to its gradient colors.
/// Currently only `primary` is supported — additional palettes
/// will be added once designed in Figma.
enum LeaguePalette: String, CaseIterable, Sendable {
    case primary

    var displayName: String {
        switch self {
        case .primary: return "Purple"
        }
    }

    /// Top color of the gradient (225 deg, 0%).
    var gradientStart: Color {
        switch self {
        case .primary: return Theme.Color.Match.Gradient.purpleStart
        }
    }

    /// Bottom color of the gradient (225 deg, 72%).
    var gradientEnd: Color {
        switch self {
        case .primary: return Theme.Color.Match.Gradient.purpleEnd
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: gradientStart, location: 0.0),
                .init(color: gradientEnd, location: 0.72)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Resolve a database key to a palette, defaulting to `.primary`.
    static func from(key: String) -> LeaguePalette {
        LeaguePalette(rawValue: key) ?? .primary
    }
}
