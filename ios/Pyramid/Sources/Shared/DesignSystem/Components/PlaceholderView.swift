import SwiftUI

/// Configurable placeholder for empty states, error states, and other
/// full-screen messages. Use different configurations at the call site
/// to produce empty, error, or informational placeholders.
struct PlaceholderView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var onAction: (() -> Void)?
    var onAsyncAction: (() async -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
                .accessibilityHidden(true)

            Text(title)
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .multilineTextAlignment(.center)

            if let buttonTitle {
                if let onAsyncAction {
                    Button {
                        Task { await onAsyncAction() }
                    } label: {
                        Text(buttonTitle)
                    }
                    .themed(.primary)
                    .padding(.top, Theme.Spacing.s20)
                } else if let onAction {
                    Button(buttonTitle, action: onAction)
                        .themed(.primary)
                        .padding(.top, Theme.Spacing.s20)
                }
            }
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
