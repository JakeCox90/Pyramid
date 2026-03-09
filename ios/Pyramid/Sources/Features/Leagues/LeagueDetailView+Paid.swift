import SwiftUI

// MARK: - Paid league header badge

/// Injected into LeagueDetailView via conditional rendering.
/// Rendered above the members list when the league type is paid and round is active.
struct PaidLeagueBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: SFSymbol.trophyFill)
                .font(.caption)
            Text("Paid League")
                .font(.DS.caption1)
        }
        .foregroundStyle(Color(hex: "FFD60A"))
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s1)
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
            HStack(spacing: DS.Spacing.s3) {
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
            Image(systemName: SFSymbol.trophyFill)
                .foregroundStyle(Color.DS.Semantic.warning)
        case .active:
            Image(systemName: SFSymbol.success)
                .foregroundStyle(Color.DS.Semantic.success)
        case .eliminated:
            Image(systemName: SFSymbol.failure)
                .foregroundStyle(Color.DS.Semantic.error)
        }
    }

    private var memberInfo: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(member.pseudonym ?? member.profiles.displayLabel)
                .font(.DS.headline)
                .foregroundStyle(Color.DS.Neutral.n900)

            if let eliminatedGw = member.eliminatedInGameweekId {
                Text("Eliminated GW\(eliminatedGw)")
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Semantic.error)
            }
        }
    }

    @ViewBuilder private var prizeInfo: some View {
        if let prizePence = member.prizePence, prizePence > 0 {
            VStack(alignment: .trailing, spacing: DS.Spacing.s1) {
                Text(formatPence(prizePence))
                    .font(.DS.headline)
                    .foregroundStyle(Color(hex: "30D158"))
                Text("Prize")
                    .font(.DS.caption2)
                    .foregroundStyle(Color.DS.Neutral.n500)
            }
        } else if !deadlinePassed {
            Image(systemName: SFSymbol.lockedPick)
                .font(.DS.caption1)
                .foregroundStyle(Color.DS.Neutral.n300)
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
