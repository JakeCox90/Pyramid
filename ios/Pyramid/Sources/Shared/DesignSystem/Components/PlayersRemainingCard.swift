import SwiftUI

struct PlayersRemainingCard: View {
    let remaining: String
    var onSeeResults: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Theme.Spacing.s10) {
                Text("\(remaining) players remaining")
                    .font(Theme.Typography.h3)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
            }
            .padding(.vertical, Theme.Spacing.s40)

            Divider()
                .background(Color.white.opacity(0.1))

            if let onSeeResults {
                Button(action: onSeeResults) {
                    Text("LAST WEEK'S RESULTS")
                        .font(Theme.Typography.label01)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .default
                        )
                        .frame(maxWidth: .infinity)
                        .padding(
                            .vertical,
                            Theme.Spacing.s30
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text("LAST WEEK'S RESULTS")
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .frame(maxWidth: .infinity)
                    .padding(
                        .vertical, Theme.Spacing.s30
                    )
            }
        }
        .background(Color(hex: "2C243D"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r50
            )
        )
    }
}
