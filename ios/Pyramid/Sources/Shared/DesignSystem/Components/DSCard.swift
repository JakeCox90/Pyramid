import SwiftUI

// MARK: - DS Card

struct DSCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(Theme.Spacing.s40)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
            .themeShadow(Theme.Shadow.md)
    }
}

// MARK: - Pick Status Badge

enum PickStatus {
    case survived, eliminated, pending, void

    var label: String {
        switch self {
        case .survived:  return "Survived"
        case .eliminated: return "Eliminated"
        case .pending:   return "Pending"
        case .void:      return "Void"
        }
    }

    var foreground: Color {
        switch self {
        case .survived:   return Theme.Color.Status.Success.resting
        case .eliminated: return Theme.Color.Status.Error.resting
        case .pending:    return Theme.Color.Content.Text.subtle
        case .void:       return Theme.Color.Status.Warning.resting
        }
    }

    var background: Color {
        switch self {
        case .survived:   return Theme.Color.Status.Success.subtle
        case .eliminated: return Theme.Color.Status.Error.subtle
        case .pending:    return Theme.Color.Surface.Background.page
        case .void:       return Theme.Color.Status.Warning.subtle
        }
    }
}

struct PickStatusBadge: View {
    let status: PickStatus

    var body: some View {
        Text(status.label)
            .font(Theme.Typography.caption1)
            .fontWeight(.semibold)
            .foregroundStyle(status.foreground)
            .padding(.vertical, Theme.Spacing.s10)
            .padding(.horizontal, Theme.Spacing.s20)
            .background(status.background)
            .clipShape(Capsule())
    }
}

// MARK: - League Card

struct LeagueCard: View {
    let leagueName: String
    let memberCount: Int
    let gameweek: Int
    let pickStatus: PickStatus

    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
                HStack {
                    Text(leagueName)
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    Spacer()
                    PickStatusBadge(status: pickStatus)
                }

                HStack(spacing: Theme.Spacing.s30) {
                    Label("\(memberCount) players", systemImage: Theme.Icon.League.members)
                    Label("GW\(gameweek)", systemImage: Theme.Icon.Pick.gameweek)
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
        }
    }
}
