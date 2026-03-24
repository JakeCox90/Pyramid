#if DEBUG
import SwiftUI

// MARK: - Flag Tab

extension ComponentBrowserView {
    var flagContent: some View {
        Group {
            flagsSection
            liveFlagSection
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

            ComponentCaption(text: "Variants")
            HStack(spacing: Theme.Spacing.s20) {
                Flag(
                    label: "Success",
                    variant: .success
                )
                Flag(
                    label: "Error",
                    variant: .error
                )
                Flag(
                    label: "Neutral",
                    variant: .neutral
                )
                Flag(
                    label: "Warning",
                    variant: .warning
                )
            }

            ComponentCaption(
                text: "Pick status (domain mapping)"
            )
            HStack(spacing: Theme.Spacing.s20) {
                Flag(
                    label: PickStatus.survived.label,
                    variant: PickStatus.survived
                        .flagVariant
                )
                Flag(
                    label: PickStatus.eliminated.label,
                    variant: PickStatus.eliminated
                        .flagVariant
                )
                Flag(
                    label: PickStatus.pending.label,
                    variant: PickStatus.pending
                        .flagVariant
                )
                Flag(
                    label: PickStatus.void.label,
                    variant: PickStatus.void.flagVariant
                )
            }
        }
    }
}

// MARK: - LiveFlag

private extension ComponentBrowserView {
    var liveFlagSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "LiveFlag")

            HStack(spacing: Theme.Spacing.s20) {
                LiveFlag()
                Text("Match in progress")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .default
                    )
            }
            .padding(Theme.Spacing.s30)
            .background(
                Theme.Color.Surface.Background
                    .container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r20
                )
            )
        }
    }
}
#endif
