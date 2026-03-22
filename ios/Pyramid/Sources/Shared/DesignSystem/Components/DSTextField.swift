import SwiftUI

// MARK: - DS Text Field

struct DSTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var errorMessage: String? = nil
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.subtle)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Color.Content.Text.default)
            .padding(.horizontal, Theme.Spacing.s30)
            .frame(height: 48)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.default)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
            .focused($isFocused)

            if let error = errorMessage {
                Text(error)
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return Theme.Color.Status.Error.resting }
        if isFocused { return Theme.Color.Primary.resting }
        return Theme.Color.Border.default
    }
}
