#if DEBUG
import SwiftUI

// MARK: - Flag Tab

extension ComponentBrowserView {
    var flagContent: some View {
        Group {
            flagsSection
        }
    }
}

// MARK: - Flags

private extension ComponentBrowserView {
    var flagsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "Flag")

            ComponentCaption(text: "Intents")
            HStack(spacing: Theme.Spacing.s20) {
                Flag(
                    label: "Success",
                    intent: .success
                )
                Flag(
                    label: "Error",
                    intent: .error
                )
                Flag(
                    label: "Neutral",
                    intent: .neutral
                )
                Flag(
                    label: "Warning",
                    intent: .warning
                )
            }

            ComponentCaption(
                text: "Pick status (domain mapping)"
            )
            HStack(spacing: Theme.Spacing.s20) {
                Flag(
                    label: PickStatus.survived.label,
                    intent: PickStatus.survived
                        .flagIntent
                )
                Flag(
                    label: PickStatus.eliminated.label,
                    intent: PickStatus.eliminated
                        .flagIntent
                )
                Flag(
                    label: PickStatus.pending.label,
                    intent: PickStatus.pending
                        .flagIntent
                )
                Flag(
                    label: PickStatus.void.label,
                    intent: PickStatus.void.flagIntent
                )
            }
        }
    }
}
#endif
