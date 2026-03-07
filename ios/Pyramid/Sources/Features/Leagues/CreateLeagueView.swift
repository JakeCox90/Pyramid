import SwiftUI

struct CreateLeagueView: View {
    @StateObject private var viewModel = CreateLeagueViewModel()
    @Environment(\.dismiss) private var dismiss

    var onLeagueCreated: ((CreateLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.DS.Background.primary.ignoresSafeArea()

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
        }
    }

    private var createForm: some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                DSTextField(
                    label: "League Name",
                    text: $viewModel.leagueName,
                    placeholder: "e.g. Sunday League Heroes",
                    errorMessage: viewModel.nameValidationMessage ?? viewModel.errorMessage
                )
                .autocorrectionDisabled()

                Text("Give your league a unique name. You'll get a join code to share with friends.")
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Neutral.n500)
            }

            Button("Create League") {
                Task { await viewModel.submit() }
            }
            .dsStyle(.primary, isLoading: viewModel.isLoading)
            .disabled(viewModel.isLoading || !viewModel.isNameValid)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }
}
