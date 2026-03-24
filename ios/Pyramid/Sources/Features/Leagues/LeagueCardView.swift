import SwiftUI

struct LeagueCardView: View {
    let league: League

    private var palette: LeaguePalette {
        LeaguePalette.from(key: league.colorPalette)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            details
        }
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
        )
        .themeShadow(Theme.Shadow.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
}

// MARK: - Header

extension LeagueCardView {
    private var header: some View {
        HStack(spacing: Theme.Spacing.s30) {
            Text(league.emoji)
                .font(.system(size: 28))

            Text(league.name)
                .font(Theme.Typography.subhead)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            statusBadge
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s30)
        .background(palette.gradient)
    }

    @ViewBuilder private var statusBadge: some View {
        switch league.status {
        case .pending:
            Flag(
                label: "Waiting",
                variant: .warning
            )
        case .active:
            Flag(
                label: "Active",
                variant: .success
            )
        case .completed:
            Flag(
                label: "Finished",
                variant: .neutral
            )
        case .cancelled:
            Flag(
                label: "Cancelled",
                variant: .error
            )
        }
    }
}

// MARK: - Details

extension LeagueCardView {
    private var details: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s20
        ) {
            if let description = league.description,
               !description.isEmpty {
                Text(description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                    .lineLimit(2)
            }

            HStack(spacing: Theme.Spacing.s30) {
                Label {
                    Text(memberText)
                } icon: {
                    Image(
                        systemName: Theme.Icon.League.members
                    )
                }

                Label {
                    Text(league.status.displayName)
                } icon: {
                    Image(
                        systemName: Theme.Icon.Pick.gameweek
                    )
                }
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Color.Surface.Background.container
        )
    }

    private var memberText: String {
        if let count = league.memberCount {
            return "\(count) players"
        }
        return "—"
    }

    private var accessibilityText: String {
        var parts = [
            league.emoji,
            league.name,
            league.status.displayName
        ]
        if let count = league.memberCount {
            parts.append("\(count) players")
        }
        if let desc = league.description {
            parts.append(desc)
        }
        return parts.joined(separator: ", ")
    }
}
