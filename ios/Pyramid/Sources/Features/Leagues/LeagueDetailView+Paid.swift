import SwiftUI

// MARK: - Paid league header badge

/// Injected into LeagueDetailView via conditional rendering.
/// Rendered above the members list when the league type is paid and round is active.
struct PaidLeagueBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: Theme.Icon.League.trophyFill)
                .font(Theme.Typography.caption)
            Text("Paid League")
                .font(Theme.Typography.overline)
        }
        .foregroundStyle(Theme.Color.Status.Warning.resting)
        .padding(.horizontal, Theme.Spacing.s30)
        .padding(.vertical, Theme.Spacing.s10)
        .background(Theme.Color.Status.Warning.resting.opacity(0.15))
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
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)

            if let eliminatedGw = member.eliminatedInGameweekId {
                Text("Eliminated GW\(eliminatedGw)")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            }
        }
    }

    @ViewBuilder private var prizeInfo: some View {
        if let prizePence = member.prizePence, prizePence > 0 {
            VStack(alignment: .trailing, spacing: Theme.Spacing.s10) {
                Text(formatPence(prizePence))
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(Theme.Color.Status.Success.resting)
                Text("Prize")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
        } else if !deadlinePassed {
            Image(systemName: Theme.Icon.Pick.locked)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Border.default)
        }
    }

    private func positionEmoji(_ position: Int) -> String {
        switch position {
        case 1: return "\u{1F947}"
        case 2: return "\u{1F948}"
        case 3: return "\u{1F949}"
        default: return "\(position)th"
        }
    }

    private func formatPence(_ pence: Int) -> String {
        let pounds = Double(pence) / 100
        return String(format: "\u{a3}%.2f", pounds)
    }
}
