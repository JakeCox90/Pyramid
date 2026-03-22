import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading,
                   viewModel.homeData == nil {
                    loadingView
                } else if let error = viewModel.errorMessage,
                          viewModel.homeData == nil {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { countdownToolbar }
            .toolbarBackground(.hidden, for: .navigationBar)
            .background(
                Theme.Color.Surface.Background.page
                    .ignoresSafeArea()
            )
            .task { await viewModel.load() }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            ProgressView()
                .tint(Theme.Color.Content.Text.subtle)
            Text("Loading...")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(
        _ message: String
    ) -> some View {
        ErrorStateView(message: message) {
            await viewModel.load()
        }
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s40) {
                if let context = viewModel.currentPick {
                    matchCard(context)
                } else {
                    matchCardEmpty()
                }

                playersRemainingCard()

                previousPicksSection()
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.bottom, Theme.Spacing.s80)
        }
        .refreshable { await viewModel.load() }
        .onDisappear {
            viewModel.stopPolling()
            viewModel.stopCountdown()
        }
    }
}
