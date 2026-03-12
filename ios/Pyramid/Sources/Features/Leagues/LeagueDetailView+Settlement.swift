import SwiftUI

// MARK: - Settlement Banner

extension LeagueDetailView {
    var currentUserSettledPick: MemberPick? {
        guard let userId = appState.session?.user.id.uuidString else { return nil }
        let pick = viewModel.lockedPicks[userId]
        guard pick?.result == .survived || pick?.result == .eliminated else { return nil }
        return pick
    }

    @ViewBuilder var mySettlementBanner: some View {
        if let pick = currentUserSettledPick {
            settlementBannerView(pick: pick)
        }
    }

    func settlementBannerView(pick: MemberPick) -> some View {
        Button { showSettlementResult = true } label: {
            DSCard {
                HStack(spacing: Theme.Spacing.s30) {
                    Image(systemName: pick.result == .survived
                        ? Theme.Icon.Status.success
                        : Theme.Icon.Status.failure)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            pick.result == .survived
                                ? Theme.Color.Status.Success.resting
                                : Theme.Color.Status.Error.resting
                        )
                    VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                        Text(pick.result == .survived
                            ? NSLocalizedString(
                                "settlement.banner.survived",
                                value: "You Survived!",
                                comment: "Banner title when player survived"
                            )
                            : NSLocalizedString(
                                "settlement.banner.eliminated",
                                value: "You Were Eliminated",
                                comment: "Banner title when player was eliminated"
                            )
                        )
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                        Text(NSLocalizedString(
                            "settlement.banner.tap_to_view",
                            value: "Tap to see your result",
                            comment: "Banner subtitle prompting user to tap"
                        ))
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.s40)
    }
}
