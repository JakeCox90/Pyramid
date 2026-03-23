#if DEBUG
import SwiftUI

// MARK: - Icons

extension TokenBrowserView {
    var iconSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
            IconGroup(title: "Navigation", icons: [
                ("home", Theme.Icon.Navigation.home),
                ("leagues", Theme.Icon.Navigation.leagues),
                ("profile", Theme.Icon.Navigation.profile),
                (
                    "notifications",
                    Theme.Icon.Navigation.notifications
                ),
                (
                    "notifDisabled",
                    Theme.Icon.Navigation.notificationsDisabled
                ),
                (
                    "disclosure",
                    Theme.Icon.Navigation.disclosure
                ),
                ("add", Theme.Icon.Navigation.add)
            ])

            IconGroup(title: "League", icons: [
                ("trophy", Theme.Icon.League.trophy),
                ("trophyFill", Theme.Icon.League.trophyFill),
                (
                    "trophyCircle",
                    Theme.Icon.League.trophyCircle
                ),
                ("members", Theme.Icon.League.members),
                ("join", Theme.Icon.League.join),
                ("create", Theme.Icon.League.create),
                ("paid", Theme.Icon.League.paid)
            ])

            IconGroup(title: "Pick", icons: [
                ("gameweek", Theme.Icon.Pick.gameweek),
                ("deadline", Theme.Icon.Pick.deadline),
                (
                    "timeRemaining",
                    Theme.Icon.Pick.timeRemaining
                ),
                ("locked", Theme.Icon.Pick.locked),
                (
                    "pseudonymous",
                    Theme.Icon.Pick.pseudonymous
                ),
                ("noRepeat", Theme.Icon.Pick.noRepeat),
                ("history", Theme.Icon.Pick.history)
            ])

            IconGroup(title: "Wallet", icons: [
                ("empty", Theme.Icon.Wallet.empty),
                ("topUp", Theme.Icon.Wallet.topUp),
                (
                    "withdrawal",
                    Theme.Icon.Wallet.withdrawal
                ),
                ("refund", Theme.Icon.Wallet.refund),
                ("winnings", Theme.Icon.Wallet.winnings)
            ])

            IconGroup(title: "Action", icons: [
                ("copy", Theme.Icon.Action.copy),
                ("copied", Theme.Icon.Action.copied),
                ("share", Theme.Icon.Action.share)
            ])

            IconGroup(title: "Status", icons: [
                ("success", Theme.Icon.Status.success),
                ("failure", Theme.Icon.Status.failure),
                ("error", Theme.Icon.Status.error),
                ("errorFill", Theme.Icon.Status.errorFill),
                ("info", Theme.Icon.Status.info)
            ])
        }
    }
}

// MARK: - Supporting Types

private struct IconGroup: View {
    let title: String
    let icons: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            SubsectionHeader(title: title)
            VStack(spacing: Theme.Spacing.s10) {
                ForEach(icons, id: \.0) { name, symbol in
                    HStack(spacing: Theme.Spacing.s30) {
                        Image(systemName: symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                Theme.Color.Surface.Background
                                    .container
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: Theme.Radius.r10
                                )
                            )
                        Text(name)
                            .font(Theme.Typography.body)
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )
                        Spacer()
                        Text(symbol)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(
                                Theme.Color.Content.Text.subtle
                            )
                    }
                }
            }
        }
    }
}
#endif
