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
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(label)
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n700)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.DS.body)
            .foregroundStyle(Color.DS.Neutral.n900)
            .padding(.horizontal, DS.Spacing.s3)
            .frame(height: 48)
            .background(Color.DS.Neutral.n000)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
            .focused($isFocused)

            if let error = errorMessage {
                Text(error)
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Semantic.error)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return .DS.Semantic.error }
        if isFocused { return .DS.Brand.primary }
        return .DS.Neutral.n300
    }
}
