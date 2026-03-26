#if DEBUG
import SwiftUI

struct InputFieldDemo: View {
    @State private var text = ""
    @State private var showError = false
    @State private var isSecure = false
    @State private var label = "Default"

    var body: some View {
        DemoPage {
            InputField(
                label: label,
                text: $text,
                placeholder: "Enter text...",
                errorMessage: showError
                    ? "Invalid input" : nil,
                isSecure: isSecure
            )
        } config: {
            ConfigRow(label: "Label") {
                TextField("Label", text: $label)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Show Error") {
                Toggle("", isOn: $showError)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Secure") {
                Toggle("", isOn: $isSecure)
                    .labelsHidden()
            }
        }
    }
}

struct EmojiPickerDemo: View {
    @State private var selected = "⚽"

    var body: some View {
        DemoPageStatic {
            EmojiPicker(selected: $selected)
        }
    }
}

struct PalettePickerDemo: View {
    @State private var selected = "primary"

    var body: some View {
        DemoPageStatic {
            PalettePicker(selected: $selected)
        }
    }
}
#endif
