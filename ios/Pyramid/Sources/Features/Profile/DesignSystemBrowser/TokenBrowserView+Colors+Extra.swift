#if DEBUG
import SwiftUI

// MARK: - Color Tokens (continued)

extension TokenBrowserView {
    @ViewBuilder
    var colorSectionExtra: some View {
        ColorGroup(
            title: "Match > Pill",
            swatches: [
                (
                    "positive",
                    Theme.Color.Match.Pill.positive
                ),
                (
                    "negative",
                    Theme.Color.Match.Pill.negative
                ),
                (
                    "inProgress",
                    Theme.Color.Match.Pill.inProgress
                )
            ]
        )

        ColorGroup(
            title: "Match",
            swatches: [
                (
                    "winIndicator",
                    Theme.Color.Match.winIndicator
                )
            ]
        )

        ColorGroup(
            title: "Elimination",
            swatches: [
                (
                    "gradientStart",
                    Theme.Color.Elimination.gradientStart
                ),
                (
                    "gradientEnd",
                    Theme.Color.Elimination.gradientEnd
                ),
                (
                    "accent",
                    Theme.Color.Elimination.accent
                )
            ]
        )

        ColorGroup(
            title: "Form (W/D/L)",
            swatches: [
                ("win", Theme.Color.Form.win),
                ("loss", Theme.Color.Form.loss),
                ("draw", Theme.Color.Form.draw)
            ]
        )
    }
}
#endif
