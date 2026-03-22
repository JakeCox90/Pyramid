import SwiftUI

// MARK: - Countdown Timer & Gameweek Dropdown

extension HomeView {
    @ToolbarContentBuilder var countdownToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            countdownBlock
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            gameweekDropdown
        }
    }

    private var countdownBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("GAMEWEEK BEGINS")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )

            Text(countdownPrimary)
                .font(Theme.Typography.h1)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            Text(countdownSecondary)
                .font(Theme.Typography.h3)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                        .opacity(0.4)
                )
        }
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

    private var gameweekDropdown: some View {
        Menu {
            ForEach(viewModel.gameweekOptions) { gw in
                Button {
                    viewModel.selectGameweek(gw)
                } label: {
                    if gw.id == viewModel.selectedGameweek?.id {
                        Label(gw.name, systemImage: "checkmark")
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
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(Theme.Color.Content.Text.default)
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }
}
