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

// MARK: - Extended Content.Text Tokens

extension Theme.Color.Content.Text {
    /// White 30% — faint labels, tertiary info
    static let tertiary = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.3),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.3)
    )
}

// MARK: - Accent Tokens

extension Theme.Color {
    enum Accent {
        /// Warm amber/gold — GW recap button, highlight accents
        static let gold = Theme.color(light: "FFC758", dark: "FFC758")
    }
}

// MARK: - Extended Border Tokens

extension Theme.Color.Border {
    /// White 10% — light borders and dividers
    static let light = Theme.color(
        light: Theme.rgbaUIColor(32, 39, 59, 0.1),
        dark: Theme.rgbaUIColor(255, 255, 255, 0.1)
    )
}

// MARK: - Shadow Tokens

extension Theme.Color {
    enum Shadow {
        /// Small shadow — card edges, subtle depth
        static let sm = Theme.color(
            light: Theme.rgbaUIColor(0, 0, 0, 0.06),
            dark: Theme.rgbaUIColor(0, 0, 0, 0.06)
        )
        /// Medium shadow — elevated cards
        static let md = Theme.color(
            light: Theme.rgbaUIColor(0, 0, 0, 0.10),
            dark: Theme.rgbaUIColor(0, 0, 0, 0.10)
        )
        /// Large shadow — modals, sheets
        static let lg = Theme.color(
            light: Theme.rgbaUIColor(0, 0, 0, 0.12),
            dark: Theme.rgbaUIColor(0, 0, 0, 0.12)
        )
        /// Drop shadow on floating cards
        static let drop = Theme.color(
            light: Theme.rgbaUIColor(0, 0, 0, 0.25),
            dark: Theme.rgbaUIColor(0, 0, 0, 0.25)
        )
        /// Heavy drop shadow
        static let heavy = Theme.color(
            light: Theme.rgbaUIColor(0, 0, 0, 0.4),
            dark: Theme.rgbaUIColor(0, 0, 0, 0.4)
        )
    }
}

// MARK: - Confetti

extension Theme.Color {
    enum Confetti {
        /// Confetti particle colour — white
        static let particle = Theme.color(light: "FFFFFF", dark: "FFFFFF")
    }
}

// MARK: - Card Surface Tokens

extension Theme.Color.Surface {
    /// White card face (e.g. pick carousel flip)
    static let cardFace = Theme.color(light: "FFFFFF", dark: "FFFFFF")
}

// MARK: - Story Tokens

extension Theme.Color {
    enum Story {
        /// Progress bar track — white 20%
        static let progressTrack = Theme.color(
            light: Theme.rgbaUIColor(255, 255, 255, 0.2),
            dark: Theme.rgbaUIColor(255, 255, 255, 0.2)
        )
        /// Story text — always white on dark story backgrounds
        static let text = Theme.color(light: "FFFFFF", dark: "FFFFFF")
    }
}
