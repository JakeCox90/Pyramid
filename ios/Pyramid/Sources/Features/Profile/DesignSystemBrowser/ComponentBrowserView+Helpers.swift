#if DEBUG
import SwiftUI

// MARK: - Shared Helpers

struct ComponentHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.h3)
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
    }
}

struct ComponentCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
    }
}
#endif
