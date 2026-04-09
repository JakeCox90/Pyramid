import SwiftUI

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
                    .foregroundStyle(Theme.Color.Content.Text.default)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.default
                )
                .strokeBorder(
                    selected == palette.rawValue
                        ? Theme.Color.Content.Text.default
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
