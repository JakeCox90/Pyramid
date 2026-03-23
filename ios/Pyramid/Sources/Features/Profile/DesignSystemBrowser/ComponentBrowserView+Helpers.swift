#if DEBUG
import SwiftUI

// MARK: - Placeholder

extension ComponentBrowserView {
    var placeholderSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "PlaceholderView")

            ComponentCaption(
                text: "Empty state configuration"
            )
            PlaceholderView(
                icon: Theme.Icon.League.trophy,
                title: "No Leagues Yet",
                message: "Join or create a league to get started.",
                buttonTitle: "Create League",
                onAction: {}
            )
            .frame(height: 260)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )

            ComponentCaption(
                text: "Error state configuration"
            )
            PlaceholderView(
                icon: Theme.Icon.Status.error,
                title: "Something went wrong",
                message: "Failed to load data.",
                buttonTitle: "Try Again",
                onAsyncAction: {}
            )
            .frame(height: 260)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
        }
    }
}

// MARK: - Pulsing Dot

extension ComponentBrowserView {
    var pulsingDotSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "PulsingDot")
            HStack(spacing: Theme.Spacing.s20) {
                PulsingDot()
                Text("Live indicator (respects reduce motion)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
            }
            .padding(Theme.Spacing.s30)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r20
                )
            )
        }
    }
}

// MARK: - Shared Helpers

struct ComponentHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.h3)
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
    }
}

struct ComponentCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
    }
}
#endif
