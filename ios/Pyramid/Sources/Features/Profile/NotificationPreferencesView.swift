import SwiftUI

// MARK: - Colours (dark theme)

private extension Color {
    static let backgroundPrimary = Color(hex: "0A0A0A")
    static let backgroundCard = Color(hex: "1C1C1E")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let brandBlue = Color(hex: "1A56DB")
    static let successGreen = Color(hex: "30D158")
    static let separator = Color(hex: "38383A")
}

// MARK: - View

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

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
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(Color(hex: "FF453A"))
                Text("Notifications are turned off")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
            }
            Text("Enable notifications in Settings to receive pick reminders and result alerts.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.6))

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Enable in Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandBlue)
            }
        }
        .padding(16)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "FF453A").opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOTIFY ME WHEN…")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.6))
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
            .background(Color.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private var divider: some View {
        Color.separator
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private func preferenceRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.brandBlue)
                .onChange(of: isOn.wrappedValue) { _ in
                    Task { await viewModel.save() }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
