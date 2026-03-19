import SwiftUI

/// Shared empty state component — consistent styling with optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .accessibilityHidden(true)

            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text(subtitle)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .multilineTextAlignment(.center)

            if let buttonTitle, let buttonAction {
                Button(buttonTitle, action: buttonAction)
                    .dsStyle(.primary, size: .medium)
                    .padding(.top, Theme.Spacing.s20)
            }
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
