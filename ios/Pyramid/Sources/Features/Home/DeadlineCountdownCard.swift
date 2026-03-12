import SwiftUI
import Combine

struct DeadlineCountdownCard: View {
    let gameweekName: String
    let deadline: Date

    @State private var now = Date()
    @State private var timerCancellable: AnyCancellable?

    private var timeRemaining: TimeInterval {
        deadline.timeIntervalSince(now)
    }

    private var isPast: Bool {
        timeRemaining <= 0
    }

    private var isUrgent: Bool {
        timeRemaining > 0 && timeRemaining < 2 * 3600
    }

    private var isWarning: Bool {
        timeRemaining > 0 && timeRemaining < 24 * 3600
    }

    private var accentColor: Color {
        if isUrgent {
            return Theme.Color.Status.Error.resting
        } else if isWarning {
            return Theme.Color.Status.Warning.resting
        }
        return Theme.Color.Content.Text.subtle
    }

    var body: some View {
        if isPast {
            deadlinePassedView
        } else {
            countdownView
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            HStack {
                Image(systemName: "clock")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(accentColor)

                Text("\(gameweekName) Deadline")
                    .font(Theme.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor)

                Spacer()

                if isUrgent {
                    urgentBadge
                }
            }

            Text(formattedDate)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text(formattedCountdown)
                .font(Theme.Typography.title2)
                .monospacedDigit()
                .foregroundStyle(accentColor)
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
                .strokeBorder(
                    isUrgent
                        ? Theme.Color.Status.Error.resting
                            .opacity(0.3)
                        : Color.clear,
                    lineWidth: 1
                )
        )
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: - Deadline Passed

    private var deadlinePassedView: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: "clock.badge.checkmark")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Content.Text.subtle)

            Text("Deadline passed")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
        )
    }

    // MARK: - Urgent Badge

    private var urgentBadge: some View {
        Text("Closing soon!")
            .font(Theme.Typography.caption1)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.Color.Status.Error.text)
            .padding(.horizontal, Theme.Spacing.s20)
            .padding(.vertical, Theme.Spacing.s10)
            .background(Theme.Color.Status.Error.resting)
            .clipShape(Capsule())
    }

    // MARK: - Background

    private var cardBackground: Color {
        if isUrgent {
            return Theme.Color.Status.Error.subtle
        }
        return Theme.Color.Surface.Background.container
    }
}

// MARK: - Formatting

extension DeadlineCountdownCard {
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM, HH:mm"
        return formatter.string(from: deadline)
    }

    private var formattedCountdown: String {
        let total = Int(max(timeRemaining, 0))
        let days = total / 86_400
        let hours = (total % 86_400) / 3600
        let minutes = (total % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Timer

extension DeadlineCountdownCard {
    private func startTimer() {
        now = Date()
        timerCancellable = Timer.publish(
            every: 60,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { self.now = $0 }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
