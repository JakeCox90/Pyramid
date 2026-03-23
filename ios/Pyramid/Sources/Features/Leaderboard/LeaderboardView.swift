import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    private var currentUserId: String? {
        SupabaseDependency.shared.client.auth.currentSession?.user.id.uuidString
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.Color.Surface.Background.page.ignoresSafeArea()
                )
                .navigationTitle("Leaderboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .task {
                    await viewModel.loadLeaderboard()
                }
        }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.entries.isEmpty {
            PlaceholderView(
                icon: "chart.bar.fill",
                title: "No leaderboard yet",
                message: "Play in free leagues to appear here."
            )
        } else {
            listView
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.s10) {
                ForEach(viewModel.entries) { entry in
                    LeaderboardRowView(
                        entry: entry,
                        isCurrentUser: entry.userId == currentUserId
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s30)
        }
        .refreshable {
            await viewModel.loadLeaderboard()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text(message)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.Status.Error.text)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.s40)

            Button("Try Again") {
                Task { await viewModel.loadLeaderboard() }
            }
            .themed(.primary)
            .padding(.horizontal, Theme.Spacing.s40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LeaderboardView()
}
