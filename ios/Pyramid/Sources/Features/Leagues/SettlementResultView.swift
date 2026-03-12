import SwiftUI

// MARK: - Settlement Result View

struct SettlementResultView: View {
    @Environment(\.dismiss)
    private var dismiss

    @StateObject private var viewModel: SettlementResultViewModel

    var onViewStandings: (() -> Void)?

    init(
        leagueId: String,
        gameweekId: Int,
        onViewStandings: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: SettlementResultViewModel(
                leagueId: leagueId,
                gameweekId: gameweekId
            )
        )
        self.onViewStandings = onViewStandings
    }

    var body: some View {
        ZStack {
            backgroundGradient

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else if let error = viewModel.errorMessage {
                errorContent(message: error)
            } else if let data = viewModel.resultData {
                resultContent(data: data)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .task { await viewModel.load() }
    }

    // MARK: - Background

    @ViewBuilder private var backgroundGradient: some View {
        if let result = viewModel.resultData?.result {
            LinearGradient(
                colors: result == .survived
                    ? [Theme.Color.Status.Success.resting.opacity(0.25),
                       Theme.Color.Surface.Background.page]
                    : [Theme.Color.Status.Error.resting.opacity(0.25),
                       Theme.Color.Surface.Background.page],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            Theme.Color.Surface.Background.page
        }
    }

    // MARK: - Result Content

    private func resultContent(data: SettlementResultData) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s60) {
                closeButton
                heroSection(data: data)
                statsSection(data: data)
                actionsSection(data: data)
            }
            .padding(.top, Theme.Spacing.s50)
            .padding(.bottom, Theme.Spacing.s70)
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }

    // MARK: - Error Content

    private func errorContent(message: String) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            Spacer()
            Image(systemName: Theme.Icon.Status.error)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Content.Text.disabled)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
            Button(
                NSLocalizedString(
                    "settlement.action.close",
                    value: "Close",
                    comment: "Close settlement screen"
                )
            ) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
            .accessibilityLabel(
                NSLocalizedString(
                    "settlement.accessibility.close",
                    value: "Close",
                    comment: "Close button accessibility label"
                )
            )
        }
    }

    private func heroSection(data: SettlementResultData) -> some View {
        SettlementHeroSection(data: data)
    }

    private func statsSection(data: SettlementResultData) -> some View {
        SettlementStatsSection(data: data)
    }

    private func actionsSection(data: SettlementResultData) -> some View {
        SettlementActionsSection(
            data: data,
            onViewStandings: {
                dismiss()
                onViewStandings?()
            },
            onShare: {
                shareResult(data: data)
            }
        )
    }

    // MARK: - Share

    private func shareResult(data: SettlementResultData) {
        let message: String
        if data.result == .survived {
            message = String(
                format: NSLocalizedString(
                    "settlement.share.survived",
                    value: "I survived GW%d in %@ picking %@! 💪",
                    comment: "Share message for survived result"
                ),
                data.gameweekNumber,
                data.leagueName,
                data.teamName
            )
        } else {
            message = String(
                format: NSLocalizedString(
                    "settlement.share.eliminated",
                    value: "I was eliminated in GW%d of %@ after lasting %d gameweeks.",
                    comment: "Share message for eliminated result"
                ),
                data.gameweekNumber,
                data.leagueName,
                data.gameweeksLasted
            )
        }
        let viewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
        let activity = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        viewController?.present(activity, animated: true)
    }
}
