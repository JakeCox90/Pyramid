import SwiftUI

// MARK: - Countdown Section (pinned header)

extension HomeView {
    @ViewBuilder var countdownSection: some View {
        switch viewModel.gameweekPhase {
        case .upcoming:
            countdownTimerView
        case .inProgress:
            gameweekStatusView(
                title: "In Progress",
                icon: "sportscourt.fill",
                color: Theme.Color.Match.Pill.inProgress
            )
        case .finished:
            gameweekStatusView(
                title: "Complete",
                icon: "checkmark.circle.fill",
                color: Theme.Color.Content.Text.muted
            )
        case .unknown:
            EmptyView()
        }
    }

    private var countdownTimerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("GAMEWEEK BEGINS")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )

            HStack(
                alignment: .firstTextBaseline,
                spacing: 6
            ) {
                Text(countdownPrimary)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text(countdownSecondary)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gameweekStatusView(
        title: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("GAMEWEEK")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countdownPrimary: String {
        let c = viewModel.countdown
        if c.isExpired { return "0d 00h" }
        return "\(c.days)d \(c.hours)h"
    }

    private var countdownSecondary: String {
        let c = viewModel.countdown
        if c.isExpired { return "00m 00s" }
        return "\(c.minutes)m \(c.seconds)s"
    }
}
