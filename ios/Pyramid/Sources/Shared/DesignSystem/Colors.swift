import SwiftUI

// MARK: - Design System: Colours
// Single source of truth. Use these everywhere — never raw hex values.

extension Color {
    enum DS {
        // MARK: Brand
        enum Brand {
            static let primary        = Color("brand/primary")        // #1A56DB — actions, active states
            static let primaryHover   = Color("brand/primary-hover")  // #1646C0 — pressed states
            static let primarySubtle  = Color("brand/primary-subtle") // #EBF2FF — tinted backgrounds
        }

        // MARK: Neutral
        enum Neutral {
            static let n900 = Color("neutral/900") // #111827 — primary text
            static let n700 = Color("neutral/700") // #374151 — secondary text
            static let n500 = Color("neutral/500") // #6B7280 — placeholder, captions
            static let n300 = Color("neutral/300") // #D1D5DB — borders, dividers
            static let n100 = Color("neutral/100") // #F3F4F6 — subtle backgrounds
            static let n000 = Color("neutral/000") // #FFFFFF — surface / card
        }

        // MARK: Semantic
        enum Semantic {
            static let success       = Color("semantic/success")        // #16A34A — win / survived
            static let successSubtle = Color("semantic/success-subtle") // #DCFCE7
            static let error         = Color("semantic/error")          // #DC2626 — loss / eliminated
            static let errorSubtle   = Color("semantic/error-subtle")   // #FEE2E2
            static let warning       = Color("semantic/warning")        // #D97706 — deadline
            static let warningSubtle = Color("semantic/warning-subtle") // #FEF3C7
            static let info          = Color("semantic/info")           // #0891B2
            static let infoSubtle    = Color("semantic/info-subtle")    // #CFFAFE
        }

        // MARK: Background
        enum Background {
            static let primary   = Color("background/primary")   // #FFFFFF — main screens
            static let secondary = Color("background/secondary") // #F9FAFB — grouped sections
            static let elevated  = Color("background/elevated")  // #FFFFFF — cards (with shadow)
        }
    }
}
