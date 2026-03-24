import SwiftUI

struct IconBadgeConfiguration {
    let icon: String
    let label: String
    let isActive: Bool
    let tier: Int?
    let style: FlagVariant

    init(
        icon: String,
        label: String,
        isActive: Bool = true,
        tier: Int? = nil,
        style: FlagVariant = .success
    ) {
        self.icon = icon
        self.label = label
        self.isActive = isActive
        self.tier = tier
        self.style = style
    }
}

struct IconBadge: View {
    let config: IconBadgeConfiguration

    var body: some View {
        VStack(spacing: Theme.Spacing.s10) {
            ZStack {
                Circle()
                    .fill(
                        config.isActive
                            ? config.style.background
                            : Theme.Color.Surface.Background
                                .container
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: config.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        config.isActive
                            ? config.style.foreground
                            : Theme.Color.Content.Text.subtle
                                .opacity(0.4)
                    )
            }
            .overlay(alignment: .topTrailing) {
                if let tier = config.tier, config.isActive {
                    tierIndicator(tier)
                }
            }

            Text(config.label)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    config.isActive
                        ? Theme.Color.Content.Text.default
                        : Theme.Color.Content.Text.subtle
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72)
        }
    }

    private func tierIndicator(_ tier: Int) -> some View {
        Text("\(tier)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
            .frame(width: 18, height: 18)
            .background(config.style.foreground)
            .clipShape(Circle())
            .offset(x: 4, y: -4)
    }
}
