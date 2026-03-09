import SwiftUI

// MARK: - Design System: Colours
// Single source of truth. Use these everywhere — never raw hex values.

extension Color {
    enum DS {
        // MARK: Brand
        enum Brand {
            /// #1A56DB — actions, active states
            static let primary = Color(hex: "1A56DB")
            /// #1646C0 — pressed states
            static let primaryHover = Color(hex: "1646C0")
            /// #EBF2FF — tinted backgrounds
            static let primarySubtle = Color(hex: "EBF2FF")
        }

        // MARK: Neutral
        enum Neutral {
            /// #111827 — primary text (light mode)
            static let n900 = Color(hex: "111827")
            /// #374151 — secondary text (light mode)
            static let n700 = Color(hex: "374151")
            /// #6B7280 — placeholder, captions
            static let n500 = Color(hex: "6B7280")
            /// #D1D5DB — borders, dividers
            static let n300 = Color(hex: "D1D5DB")
            /// #F3F4F6 — subtle backgrounds
            static let n100 = Color(hex: "F3F4F6")
            /// #FFFFFF — surface / card
            static let n000 = Color(hex: "FFFFFF")
        }

        // MARK: Semantic (dark-mode adjusted)
        enum Semantic {
            /// #30D158 — win / survived
            static let success = Color(hex: "30D158")
            /// #DCFCE7
            static let successSubtle = Color(hex: "DCFCE7")
            /// #FF453A — loss / eliminated
            static let error = Color(hex: "FF453A")
            /// #FEE2E2
            static let errorSubtle = Color(hex: "FEE2E2")
            /// #FFD60A — deadline
            static let warning = Color(hex: "FFD60A")
            /// #FEF3C7
            static let warningSubtle = Color(hex: "FEF3C7")
            /// #0A84FF — informational
            static let info = Color(hex: "0A84FF")
            /// #CFFAFE
            static let infoSubtle = Color(hex: "CFFAFE")
        }

        // MARK: Background (dark theme)
        enum Background {
            /// #0A0A0A — main screens
            static let primary = Color(hex: "0A0A0A")
            /// #1C1C1E — grouped sections, cards
            static let secondary = Color(hex: "1C1C1E")
            /// #2C2C2E — modals, sheets
            static let elevated = Color(hex: "2C2C2E")
        }

        // MARK: Text
        enum Text {
            /// #FFFFFF — primary text
            static let primary = Color.white
            /// White at 60% opacity — secondary text
            static let secondary = Color.white.opacity(0.6)
            /// White at 50% opacity — tertiary text
            static let tertiary = Color.white.opacity(0.5)
        }

        // MARK: Separator
        /// #38383A — dividers, borders (dark theme)
        static let separator = Color(hex: "38383A")
    }
}
