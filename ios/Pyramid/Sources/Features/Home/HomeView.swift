import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.homeData == nil {
                    loadingView
                } else if let error = viewModel.errorMessage,
                          viewModel.homeData == nil {
                    errorView(error)
                } else if let data = viewModel.homeData {
                    contentView(data)
                } else {
                    loadingView
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .background(
                Theme.Color.Surface.Background.page.ignoresSafeArea()
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
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) {
            await viewModel.load()
        }
    }

    // MARK: - Content

    func contentView(_ data: HomeData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
                summarySection(data)
                liveMatchSection()
                lastGwResultsSection(data)
                leaguesSection(data)
            }
            .padding(Theme.Spacing.s40)
        }
        .refreshable { await viewModel.load() }
        .onDisappear { viewModel.stopPolling() }
    }

    func summarySection(_ data: HomeData) -> some View {
        let aliveCount = data.memberStatuses.values
            .filter { $0 == .active }.count
        let picksNeeded = data.leagues.filter { league in
            data.picks[league.id] == nil
                && data.memberStatuses[league.id] == .active
        }.count

        return VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            HStack(spacing: Theme.Spacing.s20) {
                Circle()
                    .fill(
                        aliveCount > 0
                            ? Theme.Color.Status.Success.resting
                            : Theme.Color.Status.Error.resting
                    )
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text("Alive in \(aliveCount) league\(aliveCount == 1 ? "" : "s")")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }

            if picksNeeded > 0 {
                Text("\(picksNeeded) pick\(picksNeeded == 1 ? "" : "s") needed")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Status.Warning.resting)
            }

            if let gw = data.gameweek {
                Text(gw.name)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
        }
        .padding(Theme.Spacing.s40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
    }
}
