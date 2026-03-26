import SwiftUI

// MARK: - Stats Body

extension MatchCarouselCardStats {
    /// Figma: Frame 52 (46:4054) — x:19 y:103, w:319
    /// column, gap 16px
    var statsBody: some View {
        VStack(spacing: 16) {
            fixtureDetails
            sectionDivider
            formHeader
            formContent
            sectionDivider
            oddsHeader
            oddsContent
        }
        .padding(.horizontal, 19)
        .padding(.top, 15)
    }

    /// Figma: Frame 53 — venue + kickoff
    /// Label01, white 40%, center
    private var fixtureDetails: some View {
        VStack(spacing: 3) {
            if let venue = fixture.venue
                ?? FixtureMetadata.venue(
                    forHomeTeam: fixture.homeTeamName
                ) {
                Text(venue)
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
            Text(
                fixture.kickoffAt,
                format: .dateTime
                    .weekday(.abbreviated)
                    .day(.defaultDigits)
                    .month(.abbreviated)
                    .hour(.defaultDigits(
                        amPM: .abbreviated
                    ))
                    .minute(.twoDigits)
            )
            .font(Theme.Typography.label01)
            .textCase(.uppercase)
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
        }
        .frame(maxWidth: .infinity)
    }

    /// stroke_AZHE5X: rgba(255,255,255,0.2) 1px
    var sectionDivider: some View {
        Rectangle()
            .fill(Theme.Color.Border.default)
            .frame(height: 1)
    }

    /// "Last 5 games" label — Label01, white 40%
    private var formHeader: some View {
        Text("Last 5 games")
            .font(Theme.Typography.label01)
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
    }

    /// Figma: Frame 51 — two form columns with
    /// center divider
    private var formContent: some View {
        HStack(spacing: 0) {
            formColumn(
                results: stats.homeForm,
                winPct: stats.homeWinPct
            )

            // Center vertical divider
            Rectangle()
                .fill(Theme.Color.Border.default)
                .frame(width: 1, height: 55)

            formColumn(
                results: stats.awayForm,
                winPct: stats.awayWinPct
            )
        }
    }

    /// Figma: Form column — dots row (20×20, gap 4px)
    /// + win% label (Label01, white 40%)
    private func formColumn(
        results: [FormResult],
        winPct: Int
    ) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(
                    Array(results.enumerated()),
                    id: \.offset
                ) { _, result in
                    Circle()
                        .fill(result.color)
                        .frame(width: 20, height: 20)
                }
            }
            Text("\(winPct)% Win")
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
        }
        .frame(maxWidth: .infinity)
    }

    /// "Odds" label — Label01, white 40%
    private var oddsHeader: some View {
        Text("Odds")
            .font(Theme.Typography.label01)
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
    }

    /// Figma: Frame 44 — three odds boxes (79px wide,
    /// padding 8px, radius 12px, stroke 1px)
    private var oddsContent: some View {
        HStack(spacing: 0) {
            oddsBox(label: "Home", value: stats.homeOdds)
            oddsSeparator
            oddsBox(label: "Draw", value: stats.drawOdds)
            oddsSeparator
            oddsBox(label: "Away", value: stats.awayOdds)
        }
    }

    /// Figma: layout_5U4LZS — 79px wide, padding 8px,
    /// borderRadius 12px, stroke rgba(255,255,255,0.2)
    private func oddsBox(
        label: String,
        value: String
    ) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
            Text(value)
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
        }
        .frame(width: 79)
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Theme.Color.Border.default,
                    lineWidth: 1
                )
        )
    }

    /// Horizontal line between odds boxes
    private var oddsSeparator: some View {
        Rectangle()
            .fill(Theme.Color.Border.default)
            .frame(height: 1)
    }
}
