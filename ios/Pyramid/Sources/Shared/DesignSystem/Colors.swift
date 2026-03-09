import SwiftUI

// MARK: - Design System: Colours
// Single source of truth. Use Color.DS.* everywhere — never raw hex values.
// Primitives hold asset catalog references; semantic tokens (DS.*) map roles to primitives.

// MARK: - Primitives (file-private — raw asset catalog values, not used directly in views)

private enum Primitives {
    // Brand
    static let blue500 = Color("brand/primary")
    static let blue600 = Color("brand/primary-hover")
    static let blue50 = Color("brand/primary-subtle")

    // Status
    static let green500 = Color("semantic/success")
    static let green100 = Color("semantic/success-subtle")
    static let red500 = Color("semantic/error")
    static let red100 = Color("semantic/error-subtle")
    static let yellow500 = Color("semantic/warning")
    static let yellow100 = Color("semantic/warning-subtle")
    static let cyan500 = Color("semantic/info")
    static let cyan100 = Color("semantic/info-subtle")

    // Neutrals
    static let neutral900 = Color("neutral/900")
    static let neutral700 = Color("neutral/700")
    static let neutral500 = Color("neutral/500")
    static let neutral300 = Color("neutral/300")
    static let neutral100 = Color("neutral/100")
    static let neutral000 = Color("neutral/000")

    // Backgrounds
    static let bgPrimary = Color("background/primary")
    static let bgSecondary = Color("background/secondary")
    static let bgElevated = Color("background/elevated")

    // Border / Separator
    static let borderPrimary = Color("border/primary")
}

// MARK: - Semantic tokens (public — role-based, reference primitives)

extension Color {
    enum DS {
        // MARK: Brand
        enum Brand {
            /// Actions, active states
            static let primary = Primitives.blue500
            /// Pressed states
            static let primaryHover = Primitives.blue600
            /// Tinted backgrounds
            static let primarySubtle = Primitives.blue50
        }

        // MARK: Neutral
        enum Neutral {
            /// Primary text (light mode)
            static let n900 = Primitives.neutral900
            /// Secondary text (light mode)
            static let n700 = Primitives.neutral700
            /// Placeholder, captions
            static let n500 = Primitives.neutral500
            /// Borders, dividers
            static let n300 = Primitives.neutral300
            /// Subtle backgrounds
            static let n100 = Primitives.neutral100
            /// Surface / card
            static let n000 = Primitives.neutral000
        }

        // MARK: Semantic
        enum Semantic {
            /// Win / survived
            static let success = Primitives.green500
            /// Success subtle background
            static let successSubtle = Primitives.green100
            /// Loss / eliminated
            static let error = Primitives.red500
            /// Error subtle background
            static let errorSubtle = Primitives.red100
            /// Deadline
            static let warning = Primitives.yellow500
            /// Warning subtle background
            static let warningSubtle = Primitives.yellow100
            /// Informational
            static let info = Primitives.cyan500
            /// Info subtle background
            static let infoSubtle = Primitives.cyan100
        }

        // MARK: Background
        enum Background {
            /// Main screens
            static let primary = Primitives.bgPrimary
            /// Grouped sections
            static let secondary = Primitives.bgSecondary
            /// Cards, modals (with shadow)
            static let elevated = Primitives.bgElevated
        }

        // MARK: Text
        enum Text {
            /// Primary text
            static let primary = Color.white
            /// Secondary text (60% opacity)
            static let secondary = Color.white.opacity(0.6)
            /// Tertiary text (50% opacity)
            static let tertiary = Color.white.opacity(0.5)
        }

        // MARK: Border
        enum Border {
            /// Dividers, borders (dark theme)
            static let primary = Primitives.borderPrimary
        }

        // MARK: Separator
        /// Dividers, borders (dark theme)
        static let separator = Primitives.borderPrimary
    }
}
