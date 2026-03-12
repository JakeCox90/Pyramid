import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.homeData == nil {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.homeData == nil {
                    errorView(error)
                } else if let data = viewModel.homeData {
                    contentView(data)
                } else {
                    loadingView
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
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
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Status.error)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.Status.Error.resting)

            Text("Something went wrong")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Color.Primary.resting)
        }
        .padding(Theme.Spacing.s60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    private func contentView(_ data: HomeData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
                HeroStatusCard(data: data)

                if let gw = data.gameweek, let deadline = gw.deadlineAt {
                    DeadlineCountdownCard(
                        gameweekName: gw.name,
                        deadline: deadline
                    )
                }

                actionBannersSection(data)
                leaguesSection(data)
            }
            .padding(Theme.Spacing.s40)
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    // MARK: - Action Banners (PYR-89)

    @ViewBuilder
    private func actionBannersSection(_ data: HomeData) -> some View {
        let leaguesNeedingPicks = data.leagues.filter { league in
            data.picks[league.id] == nil
                && data.memberStatuses[league.id] == .active
                && league.status == .active
                && isBeforeDeadline(data.gameweek)
        }

        if !leaguesNeedingPicks.isEmpty {
            VStack(spacing: Theme.Spacing.s20) {
                ForEach(leaguesNeedingPicks) { league in
                    ActionBannerView(
                        league: league,
                        gameweek: data.gameweek
                    )
                }
            }
        }
    }

    private func isBeforeDeadline(_ gameweek: Gameweek?) -> Bool {
        guard let deadline = gameweek?.deadlineAt else { return true }
        return Date() < deadline
    }

    // MARK: - League Summary Cards (PYR-90)

    private func leaguesSection(_ data: HomeData) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            Text("Your Leagues")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)

            if data.leagues.isEmpty {
                Text("No leagues yet. Join or create one from the Leagues tab.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            } else {
                ForEach(sortedLeagues(data)) { league in
                    LeagueSummaryCard(
                        league: league,
                        memberStatus: data.memberStatuses[league.id],
                        pick: data.picks[league.id],
                        gameweek: data.gameweek
                    )
                }
            }
        }
    }

    private func sortedLeagues(_ data: HomeData) -> [League] {
        data.leagues.sorted { lhs, rhs in
            leagueSortKey(lhs, data: data) < leagueSortKey(rhs, data: data)
        }
    }

    /// Sort key: 0 = active + no pick, 1 = active + has pick, 2 = completed/eliminated
    private func leagueSortKey(
        _ league: League,
        data: HomeData
    ) -> Int {
        let status = data.memberStatuses[league.id]
        if league.status == .completed || status == .eliminated {
            return 2
        }
        if data.picks[league.id] == nil && status == .active {
            return 0
        }
        return 1
    }
}
