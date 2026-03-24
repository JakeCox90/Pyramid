import SwiftUI

// MARK: - Activity Feed Section

extension LeagueDetailView {
    var activitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            sectionHeader
            Card {
                if viewModel.activityEvents.isEmpty {
                    emptyActivityView
                } else {
                    activityList
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var sectionHeader: some View {
        HStack {
            Text("Recent Activity")
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
            if viewModel.activityEvents.count > 5 {
                Button {
                    viewModel.showAllActivity.toggle()
                } label: {
                    Text(
                        viewModel.showAllActivity
                            ? "Show less" : "See all"
                    )
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Primary.resting
                    )
                }
                .accessibilityLabel(
                    viewModel.showAllActivity
                        ? "Show fewer activities"
                        : "See all activities"
                )
            }
        }
    }

    private var activityList: some View {
        let displayed = viewModel.showAllActivity
            ? viewModel.activityEvents
            : Array(viewModel.activityEvents.prefix(5))

        return VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s30
        ) {
            ForEach(displayed) { event in
                activityRow(event: event)
                if event.id != displayed.last?.id {
                    Divider()
                        .background(Theme.Color.Border.default)
                }
            }
        }
    }

    private func activityRow(
        event: ActivityEvent
    ) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s30) {
            Circle()
                .fill(event.dotColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
                .accessibilityHidden(true)
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s10
            ) {
                Text(event.description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Text(event.timestamp.relativeFormatted)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
            Spacer()
        }
    }

    private var emptyActivityView: some View {
        HStack {
            Spacer()
            Text("No activity yet")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.s30)
    }
}

// MARK: - Relative Date Formatting

extension Date {
    var relativeFormatted: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "Just now"
        } else if interval < 3_600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86_400 {
            let hours = Int(interval / 3_600)
            return "\(hours)h ago"
        } else if interval < 172_800 {
            return "Yesterday"
        } else if interval < 604_800 {
            let days = Int(interval / 86_400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: self)
        }
    }
}
