import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.s60) {
                Spacer()

                headerSection

                Spacer()

                formSection

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text("Pyramid")
                .font(Theme.Typography.h1)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text("Premier League Last Man Standing")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
    }

    // MARK: - Form

    private var formSection: some View {
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
            .disabled(viewModel.isLoading || viewModel.isSocialLoading)
            .padding(.top, Theme.Spacing.s20)

            Button("Create account") {
                Task { await viewModel.signUp() }
            }
            .dsStyle(.ghost)
            .disabled(viewModel.isLoading || viewModel.isSocialLoading)

            socialDivider

            socialButtons
        }
    }

    // MARK: - Social Divider

    private var socialDivider: some View {
        HStack(spacing: Theme.Spacing.s20) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Theme.Color.Content.Text.disabled.opacity(0.3))
            Text("or continue with")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .fixedSize()
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Theme.Color.Content.Text.disabled.opacity(0.3))
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: Theme.Spacing.s20) {
            appleSignInButton
            googleSignInButton
        }
    }

    // MARK: - Apple Button

    private var appleSignInButton: some View {
        Button {
            Task { await viewModel.signInWithApple() }
        } label: {
            HStack(spacing: Theme.Spacing.s20) {
                Image(systemName: "apple.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                Text("Sign in with Apple")
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 50)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.default)
                .strokeBorder(Theme.Color.Content.Text.disabled.opacity(0.2), lineWidth: 1)
        )
        .disabled(viewModel.isLoading || viewModel.isSocialLoading)
        .accessibilityLabel("Sign in with Apple")
        .overlay {
            if viewModel.isSocialLoading {
                ProgressView()
                    .tint(Theme.Color.Content.Text.default)
            }
        }
    }

    // MARK: - Google Button

    private var googleSignInButton: some View {
        Button {
            Task { await viewModel.signInWithGoogle() }
        } label: {
            HStack(spacing: Theme.Spacing.s20) {
                googleLogo
                Text("Sign in with Google")
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 50)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.default)
                .strokeBorder(Theme.Color.Content.Text.disabled.opacity(0.2), lineWidth: 1)
        )
        .disabled(viewModel.isLoading || viewModel.isSocialLoading)
        .accessibilityLabel("Sign in with Google")
        .overlay {
            if viewModel.isSocialLoading {
                ProgressView()
                    .tint(Theme.Color.Content.Text.default)
            }
        }
    }

    private var googleLogo: some View {
        GoogleGLogo()
            .frame(width: 20, height: 20)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
