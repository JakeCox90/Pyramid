import SwiftUI

struct StoryHeadlineCard: View {
    let headline: String
    let body: String

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s50) {
                Text(headline)
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Text(body)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel("\(headline). \(body)")
    }
}
