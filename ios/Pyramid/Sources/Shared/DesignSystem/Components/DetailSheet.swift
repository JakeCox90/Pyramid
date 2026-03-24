import SwiftUI

struct DetailSheetConfiguration {
    let icon: String
    let iconStyle: FlagVariant
    let title: String
    let subtitle: String?
    let metadata: [(label: String, value: String)]
    let body: String?

    init(
        icon: String,
        iconStyle: FlagVariant = .success,
        title: String,
        subtitle: String? = nil,
        metadata: [(label: String, value: String)] = [],
        body: String? = nil
    ) {
        self.icon = icon
        self.iconStyle = iconStyle
        self.title = title
        self.subtitle = subtitle
        self.metadata = metadata
        self.body = body
    }
}

struct DetailSheet: View {
    let config: DetailSheetConfiguration

    var body: some View {
        VStack(spacing: Theme.Spacing.s40) {
            heroIcon
            titleSection
            if !config.metadata.isEmpty {
                metadataSection
            }
            if let body = config.body {
                bodySection(body)
            }
        }
        .padding(Theme.Spacing.s40)
        .padding(.top, Theme.Spacing.s20)
        .frame(maxWidth: .infinity)
        .background(
            Theme.Color.Surface.Background.elevated
        )
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(config.iconStyle.background)
                .frame(width: 80, height: 80)

            Image(systemName: config.icon)
                .font(.system(size: 36))
                .foregroundStyle(config.iconStyle.foreground)
        }
    }

    private var titleSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text(config.title)
                .font(Theme.Typography.h1)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var metadataSection: some View {
        VStack(spacing: Theme.Spacing.s10) {
            ForEach(
                Array(config.metadata.enumerated()),
                id: \.offset
            ) { _, item in
                HStack {
                    Text(item.label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                    Spacer()
                    Text(item.value)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                }
            }
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
        )
    }

    private func bodySection(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.body)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.s20)
    }
}
