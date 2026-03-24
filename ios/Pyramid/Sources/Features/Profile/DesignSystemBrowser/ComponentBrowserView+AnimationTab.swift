#if DEBUG
import SwiftUI

// MARK: - Animation Tab

extension ComponentBrowserView {
    var animationContent: some View {
        Group {
            confettiSection
        }
    }
}

// MARK: - ConfettiView

extension ComponentBrowserView {
    var confettiSection: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ComponentHeader(title: "ConfettiView")

            ZStack {
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
                .fill(
                    Theme.Color.Surface.Background
                        .container
                )
                .frame(height: 160)

                ConfettiView()
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
        }
    }
}
#endif
