#if DEBUG
import SwiftUI

// MARK: - Color Tokens

extension TokenBrowserView {
    var colorSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
            ColorGroup(title: "Primary", swatches: [
                ("resting", Theme.Color.Primary.resting),
                ("pressed", Theme.Color.Primary.pressed),
                ("selected", Theme.Color.Primary.selected),
                ("text", Theme.Color.Primary.text),
                ("disabled", Theme.Color.Primary.disabled)
            ])

            ColorGroup(title: "Secondary", swatches: [
                ("resting", Theme.Color.Secondary.resting),
                ("pressed", Theme.Color.Secondary.pressed),
                ("selected", Theme.Color.Secondary.selected),
                ("text", Theme.Color.Secondary.text),
                ("disabled", Theme.Color.Secondary.disabled)
            ])

            ColorGroup(title: "Content > Text", swatches: [
                ("default", Theme.Color.Content.Text.default),
                ("subtle", Theme.Color.Content.Text.subtle),
                ("contrast", Theme.Color.Content.Text.contrast),
                ("disabled", Theme.Color.Content.Text.disabled)
            ])

            ColorGroup(title: "Content > Link", swatches: [
                ("resting", Theme.Color.Content.Link.resting),
                ("pressed", Theme.Color.Content.Link.pressed),
                ("contrast", Theme.Color.Content.Link.contrast),
                ("disabled", Theme.Color.Content.Link.disabled)
            ])

            ColorGroup(
                title: "Surface > Background",
                swatches: [
                    (
                        "container",
                        Theme.Color.Surface.Background.container
                    ),
                    (
                        "elevated",
                        Theme.Color.Surface.Background.elevated
                    ),
                    (
                        "highlight",
                        Theme.Color.Surface.Background.highlight
                    ),
                    ("page", Theme.Color.Surface.Background.page),
                    (
                        "disabled",
                        Theme.Color.Surface.Background.disabled
                    ),
                    (
                        "transparent",
                        Theme.Color.Surface.Background.transparent
                    )
                ]
            )

            ColorGroup(title: "Surface > Overlay", swatches: [
                ("default", Theme.Color.Surface.Overlay.default),
                ("heavy", Theme.Color.Surface.Overlay.heavy)
            ])

            ColorGroup(title: "Surface > Skeleton", swatches: [
                ("default", Theme.Color.Surface.Skeleton.default),
                ("heavy", Theme.Color.Surface.Skeleton.heavy)
            ])

            ColorGroup(title: "Border", swatches: [
                ("default", Theme.Color.Border.default),
                ("heavy", Theme.Color.Border.heavy)
            ])

            ColorGroup(title: "Status > Info", swatches: [
                ("resting", Theme.Color.Status.Info.resting),
                ("pressed", Theme.Color.Status.Info.pressed),
                ("text", Theme.Color.Status.Info.text),
                ("disabled", Theme.Color.Status.Info.disabled),
                ("border", Theme.Color.Status.Info.border),
                ("subtle", Theme.Color.Status.Info.subtle)
            ])

            ColorGroup(title: "Status > Error", swatches: [
                ("resting", Theme.Color.Status.Error.resting),
                ("pressed", Theme.Color.Status.Error.pressed),
                ("text", Theme.Color.Status.Error.text),
                ("disabled", Theme.Color.Status.Error.disabled),
                ("border", Theme.Color.Status.Error.border),
                ("subtle", Theme.Color.Status.Error.subtle)
            ])

            ColorGroup(title: "Status > Success", swatches: [
                ("resting", Theme.Color.Status.Success.resting),
                ("pressed", Theme.Color.Status.Success.pressed),
                ("text", Theme.Color.Status.Success.text),
                ("disabled", Theme.Color.Status.Success.disabled),
                ("border", Theme.Color.Status.Success.border),
                ("subtle", Theme.Color.Status.Success.subtle)
            ])

            ColorGroup(title: "Status > Warning", swatches: [
                ("resting", Theme.Color.Status.Warning.resting),
                ("pressed", Theme.Color.Status.Warning.pressed),
                ("text", Theme.Color.Status.Warning.text),
                ("disabled", Theme.Color.Status.Warning.disabled),
                ("border", Theme.Color.Status.Warning.border),
                ("subtle", Theme.Color.Status.Warning.subtle)
            ])

            ColorGroup(title: "Status > Breaking", swatches: [
                ("resting", Theme.Color.Status.Breaking.resting),
                ("pressed", Theme.Color.Status.Breaking.pressed),
                ("text", Theme.Color.Status.Breaking.text),
                ("disabled", Theme.Color.Status.Breaking.disabled),
                ("border", Theme.Color.Status.Breaking.border)
            ])
        }
    }
}
#endif
