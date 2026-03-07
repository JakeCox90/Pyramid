import SwiftUI

// MARK: - Design System: Spacing
// 8pt base grid. All values are multiples of 4pt.
// Use DS.Spacing everywhere — never magic numbers in layout code.

enum DS {
    enum Spacing {
        static let s1:  CGFloat = 4   // micro — icon gaps, tight groupings
        static let s2:  CGFloat = 8   // small — within components
        static let s3:  CGFloat = 12
        static let s4:  CGFloat = 16  // default — standard padding
        static let s5:  CGFloat = 20
        static let s6:  CGFloat = 24  // section gaps
        static let s8:  CGFloat = 32
        static let s10: CGFloat = 40
        static let s12: CGFloat = 48
        static let s16: CGFloat = 64

        // Semantic layout constants
        static let pageMargin:    CGFloat = 16
        static let cardPadding:   CGFloat = 16
        static let sectionGap:    CGFloat = 24
    }

    enum Radius {
        static let sm:   CGFloat = 6    // tags, badges
        static let md:   CGFloat = 10   // cards, inputs
        static let lg:   CGFloat = 16   // sheets, modals
        static let xl:   CGFloat = 24   // large feature cards
        static let full: CGFloat = 9999 // pills, avatars
    }

    enum Shadow {
        struct Style {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static let sm = Style(color: .black.opacity(0.06), radius: 2,  x: 0, y: 1)
        static let md = Style(color: .black.opacity(0.10), radius: 8,  x: 0, y: 2)
        static let lg = Style(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Shadow modifier

extension View {
    func dsShadow(_ style: DS.Shadow.Style) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
