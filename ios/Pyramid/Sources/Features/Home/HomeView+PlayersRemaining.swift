import SwiftUI

// MARK: - Players Remaining Card

extension HomeView {
    @ViewBuilder
    func playersRemainingCard() -> some View {
        let remaining = viewModel.playersRemaining
        if !remaining.isEmpty {
            VStack(spacing: 0) {
                VStack(spacing: Theme.Spacing.s10) {
                    Text(remaining)
                        .font(Theme.Typography.h3)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )

                    Text("PLAYERS REMAINING")
                        .font(Theme.Typography.label01)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                                .opacity(0.4)
                        )
                }
                .padding(.vertical, Theme.Spacing.s40)

                Divider()
                    .background(Color.white.opacity(0.1))

                Text("SEE LAST WEEKS RESULTS")
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.s30)
            }
            .background(Color(hex: "2C243D"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r50
                )
            )
        }
    }
}
