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
                summarySection(data)

                if let gw = data.gameweek, let deadline = gw.deadlineAt {
                    DeadlineCountdownCard(
                        gameweekName: gw.name,
                        deadline: deadline
                    )
                }

                leaguesSection(data)
            }
            .padding(Theme.Spacing.s40)
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    private func summarySection(_ data: HomeData) -> some View {
        HeroStatusCard(data: data)
    }

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
                ForEach(data.leagues) { league in
                    homeLeagueRow(league, data: data)
                }
            }
        }
    }

    private func homeLeagueRow(_ league: League, data: HomeData) -> some View {
        let status = data.memberStatuses[league.id]
        let pick = data.picks[league.id]

        return HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                Text(league.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                HStack(spacing: Theme.Spacing.s20) {
                    if let status {
                        Text(status.rawValue.capitalized)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(statusColor(status))
                    }

                    if let count = league.memberCount {
                        HStack(spacing: Theme.Spacing.s10) {
                            Image(systemName: Theme.Icon.League.members)
                                .font(Theme.Typography.caption2)
                            Text("\(count)")
                                .font(Theme.Typography.caption1)
                        }
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    }
                }
            }

            Spacer()

            if let pick {
                Text(pick.teamName)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            } else if status == .active {
                Text("Pick needed")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Status.Warning.resting)
            }
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r30))
    }

    private func statusColor(_ status: LeagueMember.MemberStatus) -> Color {
        switch status {
        case .active: return Theme.Color.Status.Success.resting
        case .eliminated: return Theme.Color.Status.Error.resting
        case .winner: return Theme.Color.Status.Warning.resting
        }
    }
}
