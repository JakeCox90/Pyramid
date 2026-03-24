#if DEBUG
import SwiftUI

// MARK: - Button Tab

extension ComponentBrowserView {
    var buttonContent: some View {
        Group {
            buttonsSection
            iconButtonsSection
        }
    }
}

// MARK: - Buttons

private extension ComponentBrowserView {
    var buttonsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "Button (.themed)")

            Button("Primary") {}
                .themed(.primary)
            Button("Secondary") {}
                .themed(.secondary)
            Button("Destructive") {}
                .themed(.destructive)
            Button("Ghost") {}
                .themed(.ghost)
            Button("Loading") {}
                .themed(.primary, isLoading: true)
            Button("Disabled") {}
                .themed(.primary)
                .disabled(true)
            Button("Compact") {}
                .themed(.primary, fullWidth: false)
        }
    }
}

// MARK: - Icon Buttons

private extension ComponentBrowserView {
    var iconButtonsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "IconButton")

            HStack(spacing: Theme.Spacing.s30) {
                IconButton(
                    icon: Theme.Icon.Navigation.add,
                    variant: .primary
                ) {}
                IconButton(
                    icon: Theme.Icon.Action.share,
                    variant: .secondary
                ) {}
                IconButton(
                    icon: Theme.Icon.Status.failure,
                    variant: .destructive
                ) {}
                IconButton(
                    icon: Theme.Icon.Navigation
                        .notifications,
                    variant: .ghost
                ) {}
            }

            HStack(spacing: Theme.Spacing.s10) {
                Text("primary")
                Spacer()
                Text("secondary")
                Spacer()
                Text("destructive")
                Spacer()
                Text("ghost")
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
        }
    }
}
#endif
