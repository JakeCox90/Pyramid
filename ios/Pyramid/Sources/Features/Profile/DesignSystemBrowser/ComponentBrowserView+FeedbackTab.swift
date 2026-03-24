#if DEBUG
import SwiftUI

// MARK: - Feedback Tab

extension ComponentBrowserView {
    var feedbackContent: some View {
        Group {
            placeholderSection
            toastSection
            iconBadgeSection
            detailSheetSection
        }
    }
}

// MARK: - Placeholder

extension ComponentBrowserView {
    var placeholderSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "PlaceholderView")

            ComponentCaption(
                text: "Empty state configuration"
            )
            PlaceholderView(
                icon: Theme.Icon.League.trophy,
                title: "No Leagues Yet",
                message:
                    "Join or create a league to get started.",
                buttonTitle: "Create League",
                onAction: {}
            )
            .frame(height: 260)
            .background(
                Theme.Color.Surface.Background
                    .container
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
                Theme.Color.Surface.Background
                    .container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
        }
    }
}

// MARK: - Toast

extension ComponentBrowserView {
    var toastSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "Toast")

            Toast(config: ToastConfiguration(
                icon: "trophy.fill",
                title: "Achievement Unlocked",
                subtitle: "You earned a new badge",
                style: .success
            ))

            Toast(config: ToastConfiguration(
                icon: "exclamationmark.triangle",
                title: "Connection Lost",
                style: .warning
            ))
        }
    }
}

// MARK: - IconBadge

extension ComponentBrowserView {
    var iconBadgeSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "IconBadge")

            ComponentCaption(text: "Active badges")
            HStack(spacing: Theme.Spacing.s20) {
                IconBadge(config: IconBadgeConfiguration(
                    icon: "shield.fill",
                    label: "Survivor",
                    tier: 1,
                    style: .success
                ))
                IconBadge(config: IconBadgeConfiguration(
                    icon: "trophy.fill",
                    label: "Champion",
                    tier: 2,
                    style: .warning
                ))
            }

            ComponentCaption(text: "Locked badge")
            IconBadge(config: IconBadgeConfiguration(
                icon: "lock.fill",
                label: "Locked",
                isActive: false,
                style: .neutral
            ))
        }
    }
}

// MARK: - DetailSheet

extension ComponentBrowserView {
    var detailSheetSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "DetailSheet")

            DetailSheet(config: DetailSheetConfiguration(
                icon: "flame.fill",
                iconStyle: .warning,
                title: "Iron Wall",
                subtitle:
                    "Survive 5 consecutive gameweeks",
                metadata: [
                    ("Unlocked", "March 23, 2026"),
                    ("League", "Office League")
                ],
                body: "You survived 5 gameweeks in a row without being eliminated."
            ))
        }
    }
}

#endif
