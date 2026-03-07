import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.s6) {
                Spacer()

                VStack(spacing: DS.Spacing.s2) {
                    Text("Pyramid")
                        .font(.DS.display)
                        .foregroundStyle(Color.DS.Neutral.n900)

                    Text("Premier League Last Man Standing")
                        .font(.DS.subheadline)
                        .foregroundStyle(Color.DS.Neutral.n500)
                }

                Spacer()

                VStack(spacing: DS.Spacing.s3) {
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
                    .padding(.top, DS.Spacing.s2)

                    Button("Create account") {
                        Task { await viewModel.signUp() }
                    }
                    .dsStyle(.ghost, size: .medium)
                }

                Spacer()
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
            .background(Color.DS.Background.primary.ignoresSafeArea())
        }
    }
}
