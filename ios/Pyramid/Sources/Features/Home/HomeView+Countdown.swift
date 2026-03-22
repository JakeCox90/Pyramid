import SwiftUI

// MARK: - Countdown Header (in-page, not toolbar)

extension HomeView {
    @ViewBuilder var countdownHeader: some View {
        switch viewModel.gameweekPhase {
        case .upcoming:
            countdownTimerView
        case .inProgress:
            gameweekStatusView(
                overline: "GAMEWEEK",
                title: "In Progress",
                icon: "sportscourt.fill",
                color: Color(hex: "30D158")
            )
        case .finished:
            gameweekStatusView(
                overline: "GAMEWEEK",
                title: "Complete",
                icon: "checkmark.circle.fill",
                color: Color.white.opacity(0.5)
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
                    Color.white.opacity(0.4)
                )

            HStack(
                alignment: .firstTextBaseline,
                spacing: 8
            ) {
                Text(countdownPrimary)
                    .font(Theme.Typography.h1)
                    .foregroundStyle(.white)

                Text(countdownSecondary)
                    .font(Theme.Typography.h3)
                    .foregroundStyle(
                        Color.white.opacity(0.4)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gameweekStatusView(
        overline: String,
        title: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(overline)
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                Text(title)
                    .font(Theme.Typography.h2)
                    .foregroundStyle(.white)
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

// MARK: - Gameweek Dropdown (toolbar)

extension HomeView {
    @ToolbarContentBuilder var gameweekToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            gameweekDropdown
        }
    }

    private var gameweekDropdown: some View {
        Menu {
            ForEach(viewModel.gameweekOptions) { gw in
                Button {
                    viewModel.selectGameweek(gw)
                } label: {
                    if gw.id
                        == viewModel.selectedGameweek?.id
                    {
                        Label(
                            gw.name,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(gw.name)
                    }
                }
            }
        } label: {
            gameweekPill
        }
    }

    private var gameweekPill: some View {
        HStack(spacing: Theme.Spacing.s10) {
            Text(
                viewModel.selectedGameweek?.name
                    ?? "Gameweek"
            )
            .font(Theme.Typography.label01)

            Image(systemName: "chevron.down")
                .font(
                    .system(size: 10, weight: .bold)
                )
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}
