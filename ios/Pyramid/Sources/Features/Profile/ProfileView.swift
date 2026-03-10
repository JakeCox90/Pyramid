import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.s30) {
                Spacer()

                VStack(spacing: Theme.Spacing.s20) {
                    Image(systemName: Theme.Icon.Navigation.profile)
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                    Text("Profile")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    Text("Your profile will appear here.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }

                Spacer()

                NavigationLink(destination: NotificationPreferencesView()) {
                    Label("Notifications", systemImage: Theme.Icon.Navigation.notifications)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.s40)
                        .background(Theme.Color.Surface.Background.container)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Spacing.s40)

                Spacer()

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Color.Status.Error.text)
                        .padding(.horizontal, Theme.Spacing.s40)
                        .multilineTextAlignment(.center)
                }

                Button("Sign Out") {
                    Task {
                        let didSignOut = await viewModel.signOut()
                        if didSignOut {
                            appState.session = nil
                        }
                    }
                }
                .dsStyle(.destructive, isLoading: viewModel.isSigningOut)
                .disabled(viewModel.isSigningOut)
                .padding(.horizontal, Theme.Spacing.s40)
                .padding(.bottom, Theme.Spacing.s60)
                .accessibilityLabel("Sign Out")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
