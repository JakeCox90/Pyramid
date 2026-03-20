import SwiftUI

// MARK: - Member Row

struct MemberRow: View {
    let member: LeagueMember
    let pick: MemberPick?
    let fixture: Fixture?
    let deadlinePassed: Bool

    @State private var livePulse = false
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        DSCard {
            HStack(spacing: Theme.Spacing.s30) {
                statusIcon

                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(member.profiles.displayLabel)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    if let eliminatedGw = member.eliminatedInGameweekId {
                        Text("Eliminated GW\(eliminatedGw)")
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Color.Status.Error.resting)
                    }
                }

                Spacer()

                pickView
            }
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

    @ViewBuilder private var pickView: some View {
        if !deadlinePassed {
            Image(systemName: Theme.Icon.Pick.locked)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Border.default)
        } else if let pick {
            if let fixture, fixture.status.isLive || fixture.status.isFinished {
                liveFixtureView(pick: pick, fixture: fixture)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(pick.teamName)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    resultBadge(for: pick.result)
                }
            }
        } else {
            Text("No pick")
                .font(Theme.Typography.caption1)
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
                    Circle()
                        .fill(Theme.Color.Status.Error.resting)
                        .frame(width: 6, height: 6)
                        .scaleEffect(reduceMotion ? 1.0 : (livePulse ? 1.4 : 1.0))
                        .animation(
                            reduceMotion
                                ? nil
                                : .easeInOut(duration: 1).repeatForever(autoreverses: true),
                            value: livePulse
                        )
                        .onAppear {
                            if !reduceMotion { livePulse = true }
                        }
                }
                Text("\(homeScore) - \(awayScore)")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .monospacedDigit()
            }
            HStack(spacing: Theme.Spacing.s10) {
                Text(pick.teamName)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                Text(fixture.status.displayLabel)
                    .font(Theme.Typography.caption2)
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
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Text("Eliminated")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        case .pending:
            Text("Pending")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        case .void:
            Text("Void")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        }
    }
}
