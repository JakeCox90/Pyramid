#if DEBUG
import SwiftUI

// MARK: - Input Tab

extension ComponentBrowserView {
    var inputContent: some View {
        Group {
            inputFieldsSection
            emojiPickerSection
            palettePickerSection
        }
    }
}

// MARK: - Input Fields

private extension ComponentBrowserView {
    var inputFieldsSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "InputField")

            InputField(
                label: "Default",
                text: $sampleText,
                placeholder: "Enter text..."
            )
            InputField(
                label: "With Error",
                text: .constant("Bad value"),
                placeholder: "Enter text...",
                errorMessage: "Invalid input"
            )
            InputField(
                label: "Secure",
                text: .constant(""),
                placeholder: "Password",
                isSecure: true
            )
        }
    }
}

// MARK: - Emoji Picker

private extension ComponentBrowserView {
    var emojiPickerSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "EmojiPicker")
            EmojiPicker(selected: $sampleEmoji)
        }
    }
}

// MARK: - Palette Picker

private extension ComponentBrowserView {
    var palettePickerSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "PalettePicker")
            PalettePicker(selected: $samplePalette)
        }
    }
}
#endif
