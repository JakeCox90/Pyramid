import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.s60) {
                Spacer()

                VStack(spacing: Theme.Spacing.s20) {
                    Text("Pyramid")
                        .font(Theme.Typography.display)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    Text("Premier League Last Man Standing")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }

                Spacer()

                VStack(spacing: Theme.Spacing.s30) {
                    DSTextField(
                        label: "Email",
                        text: $viewModel.email,
                        placeholder: "you@example.com"
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                    DSTextField(
                        label: "Password",
                        text: $viewModel.password,
                        placeholder: "Password",
                        errorMessage: viewModel.errorMessage,
                        isSecure: true
                    )
                    .textContentType(.password)

                    Button("Sign In") {
                        Task { await viewModel.signIn() }
                    }
                    .dsStyle(.primary, isLoading: viewModel.isLoading)
                    .disabled(viewModel.isLoading)
                    .padding(.top, Theme.Spacing.s20)

                    Button("Create account") {
                        Task { await viewModel.signUp() }
                    }
                    .dsStyle(.ghost, size: .medium)
                }

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
        }
    }
}
