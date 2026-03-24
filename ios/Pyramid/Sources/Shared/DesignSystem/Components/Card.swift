import SwiftUI

// MARK: - Card

struct Card<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Theme.Spacing.s40)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r40
                )
            )
            .themeShadow(Theme.Shadow.md)
    }
}
