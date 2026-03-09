import SwiftUI

// MARK: - View

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        ZStack {
            Color.DS.Background.primary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if !notificationService.isPermissionGranted {
                        permissionBanner
                            .padding(.horizontal, DS.Spacing.pageMargin)
                            .padding(.top, DS.Spacing.s4)
                    }

                    preferencesSection
                        .padding(.top, DS.Spacing.s4)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load()
            let settings = await UNUserNotificationCenter
                .current()
                .notificationSettings()
            await MainActor.run {
                notificationService.isPermissionGranted =
                    settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Permission Banner

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s2) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(Color.DS.Semantic.error)
                Text("Notifications are turned off")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.DS.Text.primary)
            }
            Text(
                "Enable notifications in Settings to receive"
                    + " pick reminders and result alerts."
            )
            .font(.caption)
            .foregroundStyle(Color.DS.Text.secondary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Enable in Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.DS.Brand.primary)
            }
        }
        .padding(DS.Spacing.s4)
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .stroke(Color.DS.Semantic.error.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOTIFY ME WHEN…")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.DS.Text.secondary)
                .padding(.horizontal, DS.Spacing.pageMargin)
                .padding(.bottom, DS.Spacing.s2)

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
            .background(Color.DS.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
    }

    private var divider: some View {
        Color.DS.separator
            .frame(height: 1)
            .padding(.leading, DS.Spacing.pageMargin)
    }

    private func preferenceRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.DS.Text.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.DS.Text.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.DS.Brand.primary)
                .onChange(of: isOn.wrappedValue) { _ in
                    Task { await viewModel.save() }
                }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.vertical, DS.Spacing.s3)
    }
}
