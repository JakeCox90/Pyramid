import SwiftUI

// MARK: - Previous Picks Section

extension HomeView {
    @ViewBuilder
    func previousPicksSection() -> some View {
        let picks = viewModel.previousPicks
        if !picks.isEmpty {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s50
            ) {
                Text("Previous picks")
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                            .opacity(0.2)
                    )

                ForEach(picks) { result in
                    previousPickCard(result)
                }
            }
            .padding(.top, Theme.Spacing.s60)
        }
    }
}

// MARK: - Previous Pick Card

extension HomeView {
    private func previousPickCard(
        _ result: LeagueResult
    ) -> some View {
        HStack(spacing: 0) {
            pickCardHomeSide(result)
            pickCardScoreCenter(result)
            pickCardAwaySide(result)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(height: 93)
        .background(pickCardGradient)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r50
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r50
            )
            .strokeBorder(
                Color.white.opacity(0.1),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.2),
            radius: 8, x: 0, y: 4
        )
    }

    private func pickCardHomeSide(
        _ result: LeagueResult
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            TeamBadge(
                teamName: result.homeTeamName,
                logoURL: result.homeTeamLogo,
                size: 36
            )
            Text(result.homeTeamShort)
                .font(Theme.Typography.body)
                .foregroundStyle(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func pickCardScoreCenter(
        _ result: LeagueResult
    ) -> some View {
        HStack(spacing: Theme.Spacing.s10) {
            resultIcon(result, isHome: true)
            Text("\(result.homeScore)")
                .font(Theme.Typography.h2)
                .foregroundStyle(.white)
                .monospacedDigit()
            Text("\u{2013}")
                .font(Theme.Typography.h3)
                .foregroundStyle(.white.opacity(0.4))
            Text("\(result.awayScore)")
                .font(Theme.Typography.h2)
                .foregroundStyle(.white)
                .monospacedDigit()
            resultIcon(result, isHome: false)
        }
    }

    private func pickCardAwaySide(
        _ result: LeagueResult
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Spacer()
            Text(result.awayTeamShort)
                .font(Theme.Typography.body)
                .foregroundStyle(.white)
            TeamBadge(
                teamName: result.awayTeamName,
                logoURL: result.awayTeamLogo,
                size: 36
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var pickCardGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "5E4E81"),
                Color(hex: "2D253D")
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    @ViewBuilder
    private func resultIcon(
        _ result: LeagueResult,
        isHome: Bool
    ) -> some View {
        let picked = result.pickedHome == isHome
        if picked && result.result == .survived {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6CCE78"))
        } else if picked && result.result == .eliminated {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )
        } else {
            EmptyView()
        }
    }
}
