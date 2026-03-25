import SwiftUI

// MARK: - App-Specific Theme Tokens
// Tokens not yet in the Figma-generated ThemeColors.swift.
// These should be promoted to Figma when the design system is next synced.

// MARK: - Match Card Colours

extension Theme.Color {
    enum Match {
        enum Gradient {
            /// 225deg gradient start — purple (pre-match / finished)
            static let purpleStart = Theme.color(light: "5E4E81", dark: "5E4E81")
            /// 225deg gradient end — shared across all phases
            static let purpleEnd = Theme.color(light: "2D253D", dark: "2D253D")
            /// 225deg gradient start — green (live)
            static let liveStart = Theme.color(light: "4E815B", dark: "4E815B")
        }
        enum Pill {
            /// Survived / live indicator
            static let positive = Theme.color(light: "51B56A", dark: "51B56A")
            /// Eliminated indicator
            static let negative = Theme.color(light: "FF453A", dark: "FF453A")
            /// In-progress countdown badge
            static let inProgress = Theme.color(light: "30D158", dark: "30D158")
        }
        /// Win indicator on result cards
        static let winIndicator = Theme.color(light: "6CCE78", dark: "6CCE78")
    }
}

// MARK: - Elimination

extension Theme.Color {
    enum Elimination {
        static let gradientStart = Theme.color(light: "8B1A1A", dark: "8B1A1A")
        static let gradientEnd = Theme.color(light: "1A0A0A", dark: "1A0A0A")
        static let accent = Theme.color(light: "813E3E", dark: "813E3E")
    }
}

// MARK: - Form Results (W/D/L in stats panels)

extension Theme.Color {
    enum Form {
        static let win = Theme.color(light: "7DC3A0", dark: "7DC3A0")
        static let loss = Theme.color(light: "F87272", dark: "F87272")
        static let draw = Theme.color(
            light: Theme.rgbaUIColor(255, 255, 255, 0.3),
            dark: Theme.rgbaUIColor(255, 255, 255, 0.3)
        )
    }
}

// MARK: - Extended Surface Tokens

extension Theme.Color.Surface.Background {
    /// Dark card tint — half-tint overlay on match cards
    static let card = Theme.color(light: "241E31", dark: "241E31")
}

// MARK: - Extended Content.Text Tokens

extension Theme.Color.Content.Text {
    /// White 60% — secondary labels, metadata
    static let secondary = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.6),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.6)
    )
    /// White 50% — venue text, muted metadata
    static let muted = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.5),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.5)
    )
    /// White 30% — faint labels, tertiary info
    static let tertiary = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.3),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.3)
    )
}

// MARK: - Extended Border Tokens

extension Theme.Color.Border {
    /// White 15% — light borders
    static let light = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.15),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.15)
    )
    /// White 10% — subtle borders, dividers
    static let subtle = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.1),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.1)
    )
    /// White 5% — barely visible separators
    static let faint = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.05),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.05)
    )
}
