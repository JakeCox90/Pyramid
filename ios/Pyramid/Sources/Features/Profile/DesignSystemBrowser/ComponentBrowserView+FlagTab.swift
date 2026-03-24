#if DEBUG
import SwiftUI

// MARK: - Flag Tab

extension ComponentBrowserView {
    var flagContent: some View {
        Group {
            badgesSection
        }
    }
}

// MARK: - Badges (Flag)

private extension ComponentBrowserView {
    var badgesSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "Badge")

            ComponentCaption(text: "Intents")
            HStack(spacing: Theme.Spacing.s20) {
                Badge(
                    label: "Success",
                    intent: .success
                )
                Badge(
                    label: "Error",
                    intent: .error
                )
                Badge(
                    label: "Neutral",
                    intent: .neutral
                )
                Badge(
                    label: "Warning",
                    intent: .warning
                )
            }

            ComponentCaption(
                text: "Pick status (domain mapping)"
            )
            HStack(spacing: Theme.Spacing.s20) {
                Badge(
                    label: PickStatus.survived.label,
                    intent: PickStatus.survived
                        .badgeIntent
                )
                Badge(
                    label: PickStatus.eliminated.label,
                    intent: PickStatus.eliminated
                        .badgeIntent
                )
                Badge(
                    label: PickStatus.pending.label,
                    intent: PickStatus.pending
                        .badgeIntent
                )
                Badge(
                    label: PickStatus.void.label,
                    intent: PickStatus.void.badgeIntent
                )
            }
        }
    }
}
#endif
