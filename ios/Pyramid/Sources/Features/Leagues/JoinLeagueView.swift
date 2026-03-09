import SwiftUI

struct JoinLeagueView: View {
    @StateObject private var viewModel = JoinLeagueViewModel()
    @Environment(\.dismiss)
    private var dismiss

    var onLeagueJoined: ((JoinLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.DS.Background.primary.ignoresSafeArea()

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
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
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
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Neutral.n500)
            }

            Button("Find League") {
                Task { await viewModel.lookupCode() }
            }
            .dsStyle(.primary, isLoading: viewModel.isLoading)
            .disabled(viewModel.isLoading || !viewModel.isCodeValid)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    // MARK: - Step: Preview

    private func previewView(_ preview: LeaguePreview) -> some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            VStack(spacing: DS.Spacing.s4) {
                Image(systemName: SFSymbol.trophy)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.DS.Brand.primary)

                DSCard {
                    VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                        Text(preview.name)
                            .font(.DS.title3)
                            .foregroundStyle(Color.DS.Neutral.n900)

                        HStack(spacing: DS.Spacing.s4) {
                            Label("\(preview.memberCount) members", systemImage: SFSymbol.members)
                            Label("Season \(preview.season)", systemImage: SFSymbol.gameweek)
                        }
                        .font(.DS.subheadline)
                        .foregroundStyle(Color.DS.Neutral.n500)
                    }
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Semantic.error)
                    .padding(.horizontal, DS.Spacing.pageMargin)
            }

            VStack(spacing: DS.Spacing.s3) {
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
            .padding(.horizontal, DS.Spacing.pageMargin)

            Spacer()
        }
    }

    // MARK: - Step: Joined

    private func joinedView(_ response: JoinLeagueResponse) -> some View {
        VStack(spacing: DS.Spacing.s8) {
            Spacer()

            Image(systemName: SFSymbol.success)
                .font(.system(size: 64))
                .foregroundStyle(Color.DS.Semantic.success)

            VStack(spacing: DS.Spacing.s2) {
                Text("You're in!")
                    .font(.DS.title1)
                    .foregroundStyle(Color.DS.Neutral.n900)

                Text(response.name)
                    .font(.DS.headline)
                    .foregroundStyle(Color.DS.Neutral.n700)
            }

            Button("Done") {
                onLeagueJoined?(response)
                dismiss()
            }
            .dsStyle(.primary)
            .padding(.horizontal, DS.Spacing.pageMargin)

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
