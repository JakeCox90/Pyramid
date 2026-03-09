import SwiftUI

// MARK: - Paid league header badge

/// Injected into LeagueDetailView via conditional rendering.
/// Rendered above the members list when the league type is paid and round is active.
struct PaidLeagueBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: Theme.Icon.League.trophyFill)
                .font(.caption)
            Text("Paid League")
                .font(Theme.Typography.caption1)
        }
        .foregroundStyle(Color(hex: "FFD60A"))
        .padding(.horizontal, Theme.Spacing.s30)
        .padding(.vertical, Theme.Spacing.s10)
        .background(Color(hex: "FFD60A").opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Paid member row additions

/// Wraps MemberRow to show paid-league extras (pseudonym, finishing position, prize).
struct PaidMemberRow: View {
    let member: LeagueMember
    let pick: MemberPick?
    let deadlinePassed: Bool

    var body: some View {
        DSCard {
            HStack(spacing: Theme.Spacing.s30) {
                positionBadge
                memberInfo
                Spacer()
                prizeInfo
            }
        }
    }

    @ViewBuilder private var positionBadge: some View {
        if let position = member.finishingPosition {
            Text(positionEmoji(position))
                .font(.system(size: 28))
        } else {
            statusIcon
        }
    }

    @ViewBuilder private var statusIcon: some View {
        switch member.status {
        case .winner:
            Image(systemName: Theme.Icon.League.trophyFill)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        case .active:
            Image(systemName: Theme.Icon.Status.success)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Image(systemName: Theme.Icon.Status.failure)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        }
    }

    private var memberInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            Text(member.pseudonym ?? member.profiles.displayLabel)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            if let eliminatedGw = member.eliminatedInGameweekId {
                Text("Eliminated GW\(eliminatedGw)")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            }
        }
    }

    @ViewBuilder private var prizeInfo: some View {
        if let prizePence = member.prizePence, prizePence > 0 {
            VStack(alignment: .trailing, spacing: Theme.Spacing.s10) {
                Text(formatPence(prizePence))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Color(hex: "30D158"))
                Text("Prize")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
        } else if !deadlinePassed {
            Image(systemName: Theme.Icon.Pick.locked)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Border.default)
        }
    }

    private func positionEmoji(_ position: Int) -> String {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(position)th"
        }
    }

    private func formatPence(_ pence: Int) -> String {
        let pounds = Double(pence) / 100
        return String(format: "£%.2f", pounds)
    }
}
