import SwiftUI

struct Toast: View {
    let config: ToastConfiguration
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: config.icon)
                .font(Theme.Typography.body)
                .foregroundStyle(config.style.foreground)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .lineLimit(1)

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.elevated
        )
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.default)
        )
        .shadow(
            color: Theme.Color.Shadow.drop,
            radius: 8, y: 4
        )
        .padding(.horizontal, Theme.Spacing.s40)
        .onTapGesture { onDismiss?() }
    }
}
