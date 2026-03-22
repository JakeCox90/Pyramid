import SwiftUI

struct CreateLeagueView: View {
    @StateObject private var viewModel = CreateLeagueViewModel()
    @Environment(\.dismiss)
    private var dismiss

    var onLeagueCreated: ((CreateLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.Surface.Background.page.ignoresSafeArea()

                if let created = viewModel.createdLeague {
                    LeagueCreatedView(response: created) {
                        onLeagueCreated?(created)
                        dismiss()
                    }
                    .transition(.opacity)
                } else {
                    createForm
                }
            }
            .navigationTitle("Create League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.createdLeague == nil {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.createdLeague != nil)
            .alert(
                "League Creation Failed",
                isPresented: $viewModel.showErrorAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    private var createForm: some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
                DSTextField(
                    label: "League Name",
                    text: $viewModel.leagueName,
                    placeholder: "e.g. Sunday League Heroes",
                    errorMessage: viewModel.nameValidationMessage ?? viewModel.errorMessage
                )
                .autocorrectionDisabled()

                Text("Give your league a unique name. You'll get a join code to share with friends.")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }

            Button("Create League") {
                Task { await viewModel.submit() }
            }
            .dsStyle(.primary, isLoading: viewModel.isLoading)
            .disabled(viewModel.isLoading || !viewModel.isNameValid)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }
}
