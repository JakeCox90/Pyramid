import SwiftUI

struct TeamsUsedPill: View {
    let teamNames: [String]
    let count: Int

    var body: some View {
        HStack(spacing: 0) {
            badgeStack
            countLabel
        }
    }

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
                .overlay(
                    Circle()
                        .stroke(
                            Theme.Color.Surface.Background.page,
                            lineWidth: 2
                        )
                )
            }
        }
    }

    private var countLabel: some View {
        Text(
            "\(count) team\(count == 1 ? "" : "s") used"
        )
        .font(Theme.Typography.caption1.bold())
        .foregroundStyle(Color.white)
        .padding(.leading, Theme.Spacing.s30)
    }
}

struct TeamsUsedPillContainer: View {
    let teamNames: [String]
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.s30) {
            TeamsUsedPill(
                teamNames: teamNames,
                count: count
            )
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}
