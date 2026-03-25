#if DEBUG
import SwiftUI

struct FlagDemo: View {
    @State private var variant: FlagVariant = .success
    @State private var label = "Survived"

    var body: some View {
        DemoPage {
            VStack(spacing: Theme.Spacing.s30) {
                Flag(label: label, variant: variant)

                ComponentCaption(
                    text: "Match status flags"
                )
                HStack(spacing: Theme.Spacing.s20) {
                    Flag(
                        label: "LIVE",
                        variant: .live
                    )
                    Flag(
                        label: "FT",
                        variant: .fullTime
                    )
                    Flag(
                        label: "SURVIVED",
                        variant: .survived
                    )
                    Flag(
                        label: "ELIMINATED",
                        variant: .eliminated
                    )
                }

                ComponentCaption(
                    text: "Pick status mapping"
                )
                HStack(spacing: Theme.Spacing.s20) {
                    Flag(
                        label: PickStatus.survived
                            .label,
                        variant: PickStatus.survived
                            .flagVariant
                    )
                    Flag(
                        label: PickStatus.eliminated
                            .label,
                        variant: PickStatus.eliminated
                            .flagVariant
                    )
                    Flag(
                        label: PickStatus.pending
                            .label,
                        variant: PickStatus.pending
                            .flagVariant
                    )
                    Flag(
                        label: PickStatus.void.label,
                        variant: PickStatus.void
                            .flagVariant
                    )
                }
            }
        } config: {
            ConfigRow(label: "Variant") {
                Picker("", selection: $variant) {
                    Text("success")
                        .tag(FlagVariant.success)
                    Text("error")
                        .tag(FlagVariant.error)
                    Text("neutral")
                        .tag(FlagVariant.neutral)
                    Text("warning")
                        .tag(FlagVariant.warning)
                    Text("live")
                        .tag(FlagVariant.live)
                    Text("fullTime")
                        .tag(FlagVariant.fullTime)
                    Text("survived")
                        .tag(FlagVariant.survived)
                    Text("eliminated")
                        .tag(FlagVariant.eliminated)
                }
            }
            ConfigDivider()
            ConfigRow(label: "Label") {
                TextField("Label", text: $label)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
        }
    }
}
#endif
