import SwiftUI

// MARK: - Design System: Colours
// Hardcoded dark-mode palette. No asset catalog dependency.
// All colours are WCAG AA compliant on their intended backgrounds.

extension Color {
    enum DS {
        // MARK: Brand
        enum Brand {
            static let primary       = Color(hex: 0x1A56DB)           // actions, active states
            static let primaryHover  = Color(hex: 0x1646C0)           // pressed states
            static let primarySubtle = Color(hex: 0x1A56DB, alpha: 0.20) // tinted backgrounds
        }

        // MARK: Neutral
        // Remapped for dark backgrounds — n900 = lightest (primary text), n000 = darkest (input surface)
        enum Neutral {
            static let n900 = Color(hex: 0xFFFFFF)                    // primary text
            static let n700 = Color(hex: 0xEBEBF5, alpha: 0.60)      // secondary text
            static let n500 = Color(hex: 0xEBEBF5, alpha: 0.30)      // placeholder / captions
            static let n300 = Color(hex: 0x38383A)                    // borders / dividers
            static let n100 = Color(hex: 0x2C2C2E)                    // subtle backgrounds
            static let n000 = Color(hex: 0x1C1C1E)                    // input / card surface
        }

        // MARK: Semantic
        enum Semantic {
            static let success       = Color(hex: 0x30D158)
            static let successSubtle = Color(hex: 0x30D158, alpha: 0.15)
            static let error         = Color(hex: 0xFF453A)
            static let errorSubtle   = Color(hex: 0xFF453A, alpha: 0.15)
            static let warning       = Color(hex: 0xFFD60A)
            static let warningSubtle = Color(hex: 0xFFD60A, alpha: 0.15)
            static let info          = Color(hex: 0x0A84FF)
            static let infoSubtle    = Color(hex: 0x0A84FF, alpha: 0.15)
        }

        // MARK: Background
        enum Background {
            static let primary   = Color(hex: 0x0A0A0A)  // main screens
            static let secondary = Color(hex: 0x1C1C1E)  // grouped sections, cards
            static let elevated  = Color(hex: 0x2C2C2E)  // modals, sheets
        }

        // MARK: Separator
        static let separator = Color(hex: 0x38383A)
    }
}

// MARK: - Hex initialiser

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double(hex         & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }
}
