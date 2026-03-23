import SwiftUI

struct PickHistoryView: View {
    @StateObject private var viewModel: PickHistoryViewModel

    init(leagueId: String) {
        _viewModel = StateObject(
            wrappedValue: PickHistoryViewModel(leagueId: leagueId)
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.picks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.picks.isEmpty {
                errorView(message: error)
            } else if viewModel.picks.isEmpty {
                emptyStateView
            } else {
                picksList
            }
        }
        .navigationTitle("My Picks")
        .navigationBarTitleDisplayMode(.large)
        .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Pick.deadline)
                .font(.system(size: 56))
                .foregroundStyle(Theme.Color.Border.default)
            Text("No picks yet")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Text("Your pick history will appear here after you make your first pick.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Status.error)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Border.default)
            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Picks List

    private var picksList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.s20) {
                ForEach(viewModel.picks) { pick in
                    PickHistoryRow(pick: pick)
                        .padding(.horizontal, Theme.Spacing.s40)
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}

// MARK: - Pick History Row

struct PickHistoryRow: View {
    let pick: Pick

    var body: some View {
        Card {
            HStack(spacing: Theme.Spacing.s30) {
                resultIcon

                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text("GW\(pick.gameweekId)")
                        .font(Theme.Typography.overline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)

                    Text(pick.teamName)
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                }

                Spacer()

                resultBadge
            }
        }
    }

    @ViewBuilder private var resultIcon: some View {
        switch pick.result {
        case .survived:
            Image(systemName: Theme.Icon.Status.success)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Image(systemName: Theme.Icon.Status.failure)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        case .void:
            Image(systemName: Theme.Icon.Status.info)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        case .pending:
            Image(systemName: Theme.Icon.Pick.timeRemaining)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
    }

    @ViewBuilder private var resultBadge: some View {
        Text(pick.result.rawValue.capitalized)
            .font(Theme.Typography.overline.bold())
            .foregroundStyle(resultColor)
            .padding(.horizontal, Theme.Spacing.s20)
            .padding(.vertical, Theme.Spacing.s10)
            .background(resultColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pill))
    }

    private var resultColor: Color {
        switch pick.result {
        case .survived: return Theme.Color.Status.Success.resting
        case .eliminated: return Theme.Color.Status.Error.resting
        case .void: return Theme.Color.Status.Warning.resting
        case .pending: return Theme.Color.Content.Text.disabled
        }
    }
}
