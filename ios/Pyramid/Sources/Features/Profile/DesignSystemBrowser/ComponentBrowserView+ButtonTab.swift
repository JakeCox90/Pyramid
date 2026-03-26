#if DEBUG
import SwiftUI

struct ButtonDemo: View {
    @State private var variant: ButtonVariant = .primary
    @State private var isLoading = false
    @State private var isDisabled = false
    @State private var fullWidth = true
    @State private var label = "Button"

    var body: some View {
        DemoPage {
            Button(label) {}
                .themed(
                    variant,
                    isLoading: isLoading,
                    fullWidth: fullWidth
                )
                .disabled(isDisabled)
        } config: {
            ConfigRow(label: "Variant") {
                Picker("", selection: $variant) {
                    Text("primary")
                        .tag(ButtonVariant.primary)
                    Text("secondary")
                        .tag(ButtonVariant.secondary)
                    Text("destructive")
                        .tag(
                            ButtonVariant.destructive
                        )
                    Text("ghost")
                        .tag(ButtonVariant.ghost)
                }
            }
            ConfigDivider()
            ConfigRow(label: "Label") {
                TextField("Label", text: $label)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Loading") {
                Toggle("", isOn: $isLoading)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Disabled") {
                Toggle("", isOn: $isDisabled)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Full Width") {
                Toggle("", isOn: $fullWidth)
                    .labelsHidden()
            }
        }
    }
}
#endif
