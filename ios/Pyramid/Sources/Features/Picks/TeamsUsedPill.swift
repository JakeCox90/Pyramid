import SwiftUI

// Figma node 14:5155 / layout_4ZKF28 + layout_4F7H2J
// Pill: padding 8px 16px 8px 12px, height 40, gap 12px
// Badge stack: gap -8px (layout_Y7SXYJ)
// Label: Inter Bold 12, left-aligned, white (style_KV3KNT)
// Fill: rgba(255,255,255,0.1) (fill_RNW9LA), border-radius 200px

struct TeamsUsedPill: View {
    let teamNames: [String]
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            badgeStack
            countLabel
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .frame(height: 40)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }

    // layout_Y7SXYJ: row, gap -8px
    private var badgeStack: some View {
        HStack(spacing: -8) {
            ForEach(
                teamNames.prefix(5), id: \.self
            ) { name in
                TeamBadge(
                    teamName: name,
                    logoURL: nil,
                    size: 24
                )
                .clipShape(Circle())
            }
        }
    }

    // style_KV3KNT: Inter Bold 12, left-aligned (NOT uppercase)
    private var countLabel: some View {
        Text(
            "\(count) team\(count == 1 ? "" : "s") used"
        )
        .font(Theme.Typography.label02)
        .foregroundStyle(Color.white)
    }
}
