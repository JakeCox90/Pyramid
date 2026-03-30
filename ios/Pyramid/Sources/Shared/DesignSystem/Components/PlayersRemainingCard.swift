import SwiftUI

// MARK: - Players Remaining Module

struct PlayersRemainingCard: View {
    let activeCount: Int
    let totalCount: Int
    let eliminatedThisWeek: Int
    let survivalStreak: Int
    let eliminatedGameweekId: Int?
    let userStatus: LeagueMember.MemberStatus
    let currentUserId: String
    let members: [MemberSummary]

    @State private var appeared = false

    var isEliminated: Bool {
        userStatus == .eliminated
    }

    private var survivingBadgeText: String {
        if percentage >= 100 {
            return "All players standing"
        }
        return "Top \(percentage)% \u{2014} Still standing"
    }

    private var eliminatedBadgeText: String {
        if let gwId = eliminatedGameweekId {
            return "Eliminated in GW \(gwId)"
        }
        return "Eliminated in GW \(survivalStreak + 1)"
    }

    var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int(
            round(
                Double(activeCount) / Double(totalCount)
                    * 100
            )
        )
    }

    private var ringProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(activeCount) / Double(totalCount)
    }

    var survivors: [MemberSummary] {
        members.filter { $0.status == .active || $0.status == .winner }
    }

    var eliminated: [MemberSummary] {
        members.filter { $0.status == .eliminated }
    }

    static let maxSurvivors = 8
    static let maxEliminated = 6

    var body: some View {
        VStack(spacing: Theme.Spacing.s40) {
            ringSection
            badgeSection
            VStack(spacing: Theme.Spacing.s30) {
                survivorAvatars
                eliminatedAvatars
            }
            statsRow
        }
        .padding(Theme.Spacing.s40)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r50
            )
        )
        .onAppear {
            withAnimation(
                .easeOut(duration: 0.8).delay(0.2)
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Ring

extension PlayersRemainingCard {
    private var ringSection: some View {
        ZStack {
            Circle()
                .stroke(
                    Theme.Color.Surface.Background.page,
                    lineWidth: 9
                )

            Circle()
                .trim(
                    from: 0,
                    to: appeared ? ringProgress : 0
                )
                .stroke(
                    isEliminated
                        ? Theme.Color.Content.Text.disabled
                        : Theme.Color.Status.Success.resting,
                    style: StrokeStyle(
                        lineWidth: 9,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(activeCount)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        isEliminated
                            ? Theme.Color.Content.Text
                                .subtle
                            : Theme.Color.Status.Success
                                .resting
                    )
                Text("of \(totalCount) left")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
        }
        .frame(width: 130, height: 130)
    }
}

// MARK: - Badge

extension PlayersRemainingCard {
    private var badgeSection: some View {
        Group {
            if isEliminated {
                badgePill(
                    text: eliminatedBadgeText,
                    foreground: Theme.Color.Status.Error
                        .resting,
                    background: Theme.Color.Status.Error
                        .subtle
                )
            } else {
                badgePill(
                    text: survivingBadgeText,
                    foreground: Theme.Color.Status.Success
                        .resting,
                    background: Theme.Color.Status.Success
                        .subtle
                )
            }
        }
    }

    private func badgePill(
        text: String,
        foreground: Color,
        background: Color
    ) -> some View {
        Text(text)
            .font(Theme.Typography.label01)
            .foregroundStyle(foreground)
            .padding(.vertical, Theme.Spacing.s10)
            .padding(.horizontal, Theme.Spacing.s30)
            .background(background)
            .clipShape(Capsule())
    }
}
