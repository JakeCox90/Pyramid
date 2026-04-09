import SwiftUI

/// Valid emojis — must match the Edge Function's VALID_EMOJIS.
let leagueEmojis: [String] = [
    "⚽", "🏆", "⚡", "🔥", "💀", "👑", "🎯", "🦁",
    "⭐", "💎", "🛡️", "🎪", "🍺", "🤝", "🏴", "🎲"
]

// MARK: - Emoji Picker

struct EmojiPicker: View {
    @Binding var selected: String

    private let columns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: Theme.Spacing.s20
        ),
        count: 4
    )

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Emoji")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            LazyVGrid(columns: columns, spacing: Theme.Spacing.s20) {
                ForEach(leagueEmojis, id: \.self) { emoji in
                    emojiButton(emoji)
                }
            }
        }
    }

    private func emojiButton(_ emoji: String) -> some View {
        Button {
            selected = emoji
        } label: {
            Text(emoji)
                .font(.system(size: 28))
                .frame(
                    maxWidth: .infinity,
                    minHeight: 48
                )
                .background(
                    emoji == selected
                        ? Theme.Color.Primary.resting
                            .opacity(0.15)
                        : Theme.Color.Surface.Background
                            .container
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Theme.Radius.default
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: Theme.Radius.default
                    )
                    .strokeBorder(
                        emoji == selected
                            ? Theme.Color.Primary.resting
                            : Theme.Color.Border.default,
                        lineWidth: emoji == selected
                            ? 2 : 1
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(emoji)
        .accessibilityAddTraits(
            emoji == selected ? .isSelected : []
        )
    }
}
