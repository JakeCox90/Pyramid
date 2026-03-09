import SwiftUI

struct JoinLeagueView: View {
    @StateObject private var viewModel = JoinLeagueViewModel()
    @Environment(\.dismiss)
    private var dismiss

    var onLeagueJoined: ((JoinLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.Surface.Background.page.ignoresSafeArea()

                switch viewModel.step {
                case .enterCode:
                    enterCodeView
                        .transition(.opacity)
                case .preview(let preview):
                    previewView(preview)
                        .transition(.opacity)
                case .joined(let response):
                    joinedView(response)
                        .transition(.opacity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if case .joined = viewModel.step {} else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: stepKey)
        }
    }

    // MARK: - Step: Enter Code

    private var enterCodeView: some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
                DSTextField(
                    label: "Join Code",
                    text: $viewModel.code,
                    placeholder: "e.g. ABC123",
                    errorMessage: viewModel.errorMessage
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: viewModel.code) { newValue in
                    let uppercased = newValue.uppercased()
                    if uppercased != newValue { viewModel.code = uppercased }
                }

                Text("Ask the league creator for the 6-character code.")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }

            Button("Find League") {
                Task { await viewModel.lookupCode() }
            }
            .dsStyle(.primary, isLoading: viewModel.isLoading)
            .disabled(viewModel.isLoading || !viewModel.isCodeValid)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    // MARK: - Step: Preview

    private func previewView(_ preview: LeaguePreview) -> some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            VStack(spacing: Theme.Spacing.s40) {
                Image(systemName: Theme.Icon.League.trophy)
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Color.Primary.resting)

                DSCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
                        Text(preview.name)
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Color.Content.Text.default)

                        HStack(spacing: Theme.Spacing.s40) {
                            Label("\(preview.memberCount) members", systemImage: Theme.Icon.League.members)
                            Label("Season \(preview.season)", systemImage: Theme.Icon.Pick.gameweek)
                        }
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    }
                }
                .padding(.horizontal, Theme.Spacing.s40)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
                    .padding(.horizontal, Theme.Spacing.s40)
            }

            VStack(spacing: Theme.Spacing.s30) {
                Button("Join League") {
                    Task { await viewModel.confirmJoin() }
                }
                .dsStyle(.primary, isLoading: viewModel.isLoading)
                .disabled(viewModel.isLoading)

                Button("Back") {
                    viewModel.resetToEnterCode()
                }
                .dsStyle(.ghost)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
        }
    }

    // MARK: - Step: Joined

    private func joinedView(_ response: JoinLeagueResponse) -> some View {
        VStack(spacing: Theme.Spacing.s70) {
            Spacer()

            Image(systemName: Theme.Icon.Status.success)
                .font(.system(size: 64))
                .foregroundStyle(Theme.Color.Status.Success.resting)

            VStack(spacing: Theme.Spacing.s20) {
                Text("You're in!")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text(response.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }

            Button("Done") {
                onLeagueJoined?(response)
                dismiss()
            }
            .dsStyle(.primary)
            .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        switch viewModel.step {
        case .enterCode: return "Join League"
        case .preview:   return "League Preview"
        case .joined:    return "Joined!"
        }
    }

    private var stepKey: String {
        switch viewModel.step {
        case .enterCode: return "enterCode"
        case .preview:   return "preview"
        case .joined:    return "joined"
        }
    }
}
