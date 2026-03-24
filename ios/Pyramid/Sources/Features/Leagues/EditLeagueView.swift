import SwiftUI

struct EditLeagueView: View {
    @StateObject private var viewModel: EditLeagueViewModel
    @Environment(\.dismiss)
    private var dismiss

    var onSaved: (() -> Void)?

    init(
        league: League,
        onSaved: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: EditLeagueViewModel(league: league)
        )
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.Surface.Background.page
                    .ignoresSafeArea()

                ScrollView {
                    VStack(
                        spacing: Theme.Spacing.s60
                    ) {
                        previewCard
                        formFields
                        saveButton
                    }
                    .padding(.horizontal, Theme.Spacing.s40)
                    .padding(.top, Theme.Spacing.s40)
                }
            }
            .navigationTitle("Edit League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(
                "Update Failed",
                isPresented: $viewModel.showErrorAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(
                    viewModel.errorMessage
                        ?? "An unknown error occurred."
                )
            }
            .onChange(of: viewModel.didSave) { saved in
                if saved {
                    onSaved?()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Subviews

extension EditLeagueView {
    private var previewCard: some View {
        LeagueCardView(
            league: League(
                id: viewModel.league.id,
                name: viewModel.name.isEmpty
                    ? "League Name"
                    : viewModel.name,
                joinCode: viewModel.league.joinCode,
                type: viewModel.league.type,
                status: viewModel.league.status,
                season: viewModel.league.season,
                createdAt: viewModel.league.createdAt,
                colorPalette: viewModel.colorPalette,
                emoji: viewModel.emoji,
                description: viewModel.description.isEmpty
                    ? nil : viewModel.description
            )
        )
    }

    private var formFields: some View {
        VStack(spacing: Theme.Spacing.s50) {
            InputField(
                label: "League Name",
                text: $viewModel.name,
                placeholder: "e.g. Sunday League Heroes",
                errorMessage: viewModel
                    .nameValidationMessage
            )
            .autocorrectionDisabled()

            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s10
            ) {
                Text("Description (optional)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )

                TextField(
                    "Short tagline for your league",
                    text: $viewModel.description,
                    axis: .vertical
                )
                .lineLimit(2...3)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .padding(.horizontal, Theme.Spacing.s30)
                .padding(.vertical, Theme.Spacing.s20)
                .background(
                    Theme.Color.Surface.Background
                        .container
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Theme.Radius.default
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: Theme.Radius.default
                    )
                    .strokeBorder(
                        descriptionBorderColor,
                        lineWidth: 1.5
                    )
                )

                if let msg = viewModel
                    .descriptionValidationMessage {
                    Text(msg)
                        .font(Theme.Typography.overline)
                        .foregroundStyle(
                            Theme.Color.Status.Error
                                .resting
                        )
                }
            }

            EmojiPicker(selected: $viewModel.emoji)

            PalettePicker(
                selected: $viewModel.colorPalette
            )
        }
    }

    private var saveButton: some View {
        Button("Save Changes") {
            Task { await viewModel.save() }
        }
        .themed(
            .primary,
            isLoading: viewModel.isLoading
        )
        .disabled(!viewModel.canSave)
        .padding(.top, Theme.Spacing.s20)
    }

    private var descriptionBorderColor: Color {
        if viewModel.descriptionValidationMessage != nil {
            return Theme.Color.Status.Error.resting
        }
        return Theme.Color.Border.default
    }
}
