import SwiftUI

// MARK: - DS Card

struct DSCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.Spacing.cardPadding)
            .background(Color.DS.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
            .dsShadow(DS.Shadow.md)
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
        case .survived:   return .DS.Semantic.success
        case .eliminated: return .DS.Semantic.error
        case .pending:    return .DS.Neutral.n700
        case .void:       return .DS.Semantic.warning
        }
    }

    var background: Color {
        switch self {
        case .survived:   return .DS.Semantic.successSubtle
        case .eliminated: return .DS.Semantic.errorSubtle
        case .pending:    return .DS.Neutral.n100
        case .void:       return .DS.Semantic.warningSubtle
        }
    }
}

struct PickStatusBadge: View {
    let status: PickStatus

    var body: some View {
        Text(status.label)
            .font(.DS.caption1)
            .fontWeight(.semibold)
            .foregroundStyle(status.foreground)
            .padding(.vertical, DS.Spacing.s1)
            .padding(.horizontal, DS.Spacing.s2)
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
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                HStack {
                    Text(leagueName)
                        .font(.DS.title3)
                        .foregroundStyle(Color.DS.Neutral.n900)
                    Spacer()
                    PickStatusBadge(status: pickStatus)
                }

                HStack(spacing: DS.Spacing.s3) {
                    Label("\(memberCount) players", systemImage: "person.2")
                    Label("GW\(gameweek)", systemImage: "calendar")
                }
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n500)
            }
        }
    }
}
