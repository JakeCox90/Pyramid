import SwiftUI

// MARK: - Teams Left Pill

extension PickCarouselView {
    /// Figma: Frame 66 (49:5858) — gradient capsule
    /// with "X teams left" + team badge rail
    /// layout_AWG1HZ: row, center, gap 4px, padding 12px 24px
    /// layout_29NVIT: row, center, gap 4px, padding 8px 12px
    /// fill_H7SDCM: gradient 225deg + rgba(255,255,255,0.1)
    /// stroke_PT8QII: rgba(255,255,255,0.1) 1px
    @ViewBuilder var teamsLeftPill: some View {
        let allTeams = extractUniqueTeams()
        let teamsLeft = allTeams.count
            - viewModel.usedTeamIds.count
        if teamsLeft > 0 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Text("\(teamsLeft) teams left")
                        .font(Theme.Typography.label02)
                        .foregroundStyle(
                            Theme.Color.Content.Text.disabled
                        )
                        .fixedSize()
                    badgeRail(teams: allTeams)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
            .background(teamsLeftBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        Theme.Color.Border.subtle,
                        lineWidth: 1
                    )
            )
        }
    }

    /// fill_H7SDCM: gradient + white 10% overlay
    private var teamsLeftBackground: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(
                        color: Theme.Color.Match.Gradient.purpleStart,
                        location: 0.0
                    ),
                    .init(
                        color: Theme.Color.Match.Gradient.purpleEnd,
                        location: 0.72
                    )
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            Theme.Color.Surface.Background.highlight
        }
    }

    /// Rail of 24×24 team badges, gap 4px.
    /// Used teams show at 0.2 opacity.
    private func badgeRail(
        teams: [(id: Int, name: String)]
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(
                teams,
                id: \.id
            ) { team in
                TeamBadge(
                    teamName: team.name,
                    logoURL: nil,
                    size: 24
                )
                .saturation(
                    viewModel.usedTeamIds
                        .contains(team.id)
                        ? 0 : 1
                )
                .opacity(
                    viewModel.usedTeamIds
                        .contains(team.id)
                        ? 0.4 : 1.0
                )
            }
        }
    }

    /// Extract unique teams from fixtures for the badge rail
    func extractUniqueTeams() -> [(id: Int, name: String)] {
        var seen = Set<Int>()
        var teams: [(id: Int, name: String)] = []
        for fixture in viewModel.fixtures {
            if seen.insert(fixture.homeTeamId).inserted {
                teams.append(
                    (fixture.homeTeamId,
                     fixture.homeTeamName)
                )
            }
            if seen.insert(fixture.awayTeamId).inserted {
                teams.append(
                    (fixture.awayTeamId,
                     fixture.awayTeamName)
                )
            }
        }
        return teams
    }
}
