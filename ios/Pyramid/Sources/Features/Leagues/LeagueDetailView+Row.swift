import SwiftUI

// MARK: - Member Row

struct MemberRow: View {
    let member: LeagueMember
    let pick: MemberPick?
    let fixture: Fixture?
    let deadlinePassed: Bool

    private let avatarSize: CGFloat = 36

    var body: some View {
        Card {
            HStack(spacing: Theme.Spacing.s30) {
                avatarWithStatus

                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(member.profiles.displayLabel)
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    if let eliminatedGw = member.eliminatedInGameweekId {
                        Text("Eliminated GW\(eliminatedGw)")
                            .font(Theme.Typography.overline)
                            .foregroundStyle(Theme.Color.Status.Error.resting)
                    }
                }

                Spacer()

                pickView
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var avatarWithStatus: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarImage
            statusBadge
                .offset(x: 2, y: 2)
        }
        .accessibilityLabel(statusAccessibilityLabel)
    }

    private var avatarImage: some View {
        Avatar(
            name: member.profiles.displayLabel,
            imageURL: member.profiles.avatarUrl,
            size: .custom(avatarSize)
        )
    }

    @ViewBuilder private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(
                        Theme.Color.Surface.Background.container,
                        lineWidth: 2
                    )
            )
    }

    private var statusColor: Color {
        switch member.status {
        case .winner: Theme.Color.Status.Warning.resting
        case .active: Theme.Color.Status.Success.resting
        case .eliminated: Theme.Color.Status.Error.resting
        }
    }

    private var statusAccessibilityLabel: String {
        switch member.status {
        case .winner: "Winner"
        case .active: "Active"
        case .eliminated: "Eliminated"
        }
    }

    @ViewBuilder private var pickView: some View {
        if !deadlinePassed {
            Image(systemName: Theme.Icon.Pick.locked)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Border.default)
                .accessibilityLabel("Pick hidden until kick-off")
        } else if let pick {
            if let fixture, fixture.status.isLive || fixture.status.isFinished {
                liveFixtureView(pick: pick, fixture: fixture)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(pick.teamName)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    resultBadge(for: pick.result)
                }
            }
        } else {
            Text("No pick")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Border.default)
        }
    }

    @ViewBuilder
    private func liveFixtureView(pick: MemberPick, fixture: Fixture) -> some View {
        let isLive = fixture.status.isLive
        let homeScore = fixture.homeScore ?? 0
        let awayScore = fixture.awayScore ?? 0

        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: Theme.Spacing.s10) {
                if isLive {
                    PulsingDot()
                        .accessibilityLabel("Live match in progress")
                }
                Text("\(homeScore) - \(awayScore)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .monospacedDigit()
            }
            HStack(spacing: Theme.Spacing.s10) {
                Text(pick.teamName)
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                Text(fixture.status.displayLabel)
                    .font(Theme.Typography.overline)
                    .foregroundStyle(
                        isLive
                            ? Theme.Color.Status.Error.resting
                            : Theme.Color.Content.Text.disabled
                    )
            }
            if fixture.status.isFinished {
                resultBadge(for: pick.result)
            }
        }
    }

    @ViewBuilder
    private func resultBadge(for result: PickResult) -> some View {
        switch result {
        case .survived:
            Text("Survived")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Text("Eliminated")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        case .pending:
            Text("Pending")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        case .void:
            Text("Void")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        }
    }
}
