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
                        ? Theme.Color.Primary.subtle
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

// MARK: - Palette Picker

struct PalettePicker: View {
    @Binding var selected: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Color")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            HStack(spacing: Theme.Spacing.s20) {
                ForEach(
                    LeaguePalette.allCases,
                    id: \.rawValue
                ) { palette in
                    paletteButton(palette)
                }
            }
        }
    }

    private func paletteButton(
        _ palette: LeaguePalette
    ) -> some View {
        Button {
            selected = palette.rawValue
        } label: {
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
            .fill(palette.gradient)
            .frame(height: 48)
            .overlay(
                Text(palette.displayName)
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.default
                )
                .strokeBorder(
                    selected == palette.rawValue
                        ? .white
                        : .clear,
                    lineWidth: 2
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(palette.displayName)
        .accessibilityAddTraits(
            selected == palette.rawValue
                ? .isSelected : []
        )
    }
}
