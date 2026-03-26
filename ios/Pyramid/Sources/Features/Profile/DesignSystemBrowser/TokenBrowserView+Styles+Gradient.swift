#if DEBUG
import SwiftUI

// MARK: - Gradient Tokens

extension TokenBrowserView {

    var gradientSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            gradientRow(
                name: "primary (story)",
                gradient: Theme.Gradient.primary
            )
            gradientRow(
                name: "match (purple)",
                gradient: LinearGradient(
                    stops: [
                        .init(
                            color: Theme.Color.Match.Gradient
                                .purpleStart,
                            location: 0.0
                        ),
                        .init(
                            color: Theme.Color.Match.Gradient
                                .purpleEnd,
                            location: 0.72
                        )
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
            gradientRow(
                name: "match (live)",
                gradient: LinearGradient(
                    stops: [
                        .init(
                            color: Theme.Color.Match.Gradient
                                .liveStart,
                            location: 0.0
                        ),
                        .init(
                            color: Theme.Color.Match.Gradient
                                .purpleEnd,
                            location: 0.72
                        )
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
            gradientRow(
                name: "elimination",
                gradient: LinearGradient(
                    colors: [
                        Theme.Color.Elimination
                            .gradientStart,
                        Theme.Color.Elimination.gradientEnd
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
        }
    }

    func gradientRow(
        name: String,
        gradient: LinearGradient
    ) -> some View {
        HStack(spacing: Theme.Spacing.s30) {
            RoundedRectangle(cornerRadius: Theme.Radius.r20)
                .fill(gradient)
                .frame(width: 48, height: 48)
            Text(name)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
            Text("linear-gradient")
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
        }
    }

}
#endif
