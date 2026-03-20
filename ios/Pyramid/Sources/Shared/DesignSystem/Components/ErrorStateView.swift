import SwiftUI

/// Shared error state component — consistent styling, accessibility, and retry support.
struct ErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    var retryAction: (() async -> Void)?

    init(
        icon: String = Theme.Icon.Status.error,
        title: String = "Something went wrong",
        message: String,
        retryAction: (() async -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .accessibilityHidden(true)

            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button {
                    Task { await retryAction() }
                } label: {
                    Text("Try Again")
                }
                .dsStyle(.primary, size: .medium)
                .padding(.top, Theme.Spacing.s20)
            }
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
