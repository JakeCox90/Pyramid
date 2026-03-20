import SwiftUI

// MARK: - View

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        ZStack {
            Theme.Color.Surface.Background.page.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if !notificationService.isPermissionGranted {
                        permissionBanner
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }

                    preferencesSection
                        .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                notificationService.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: Theme.Icon.Navigation.notificationsDisabled)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
                Text("Notifications are turned off")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
            Text("Enable notifications in Settings to receive pick reminders and result alerts.")
                .font(.caption)
                .foregroundStyle(Theme.Color.Content.Text.subtle)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Enable in Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.Primary.resting)
            }
        }
        .padding(16)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Color.Status.Error.resting.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOTIFY ME WHEN\u{2026}")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                preferenceRow(
                    title: "Pick deadlines",
                    subtitle: "Reminder 1 hour before GW kick-off",
                    isOn: $viewModel.preferences.deadlineReminders
                )
                divider
                preferenceRow(
                    title: "Pick locked",
                    subtitle: "When your match kicks off",
                    isOn: $viewModel.preferences.pickLocked
                )
                divider
                preferenceRow(
                    title: "Results",
                    subtitle: "Win, loss, or elimination alerts",
                    isOn: $viewModel.preferences.resultAlerts
                )
                divider
                preferenceRow(
                    title: "Winnings",
                    subtitle: "When funds are ready to withdraw",
                    isOn: $viewModel.preferences.winningsAlerts
                )
            }
            .background(Theme.Color.Surface.Background.container)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private var divider: some View {
        Theme.Color.Border.default
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private func preferenceRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.Color.Primary.resting)
                .onChange(of: isOn.wrappedValue) { _ in
                    Task { await viewModel.save() }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
