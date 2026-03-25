import SwiftUI

// Figma: H2H Stats Panel (node 32:5206)
// Sits behind MatchCarouselCard, revealed on swipe-up
// Background: #241E31 (fill_1EP1Y9)

// MARK: - Data Model

enum FormResult: String, Identifiable {
    case win, draw, loss

    var id: String { rawValue }

    // fill_YV73OV: #7DC3A0 (green), fill_46FMUX: #F87272 (red)
    var color: Color {
        switch self {
        case .win: return Color(hex: "7DC3A0")
        case .draw: return Color.white.opacity(0.3)
        case .loss: return Color(hex: "F87272")
        }
    }
}

struct MatchStats {
    let homeForm: [FormResult]
    let awayForm: [FormResult]
    let homeWinPct: Int
    let awayWinPct: Int
    let homeOdds: String
    let drawOdds: String
    let awayOdds: String

    static let placeholder = MatchStats(
        homeForm: [.win, .win, .loss, .win, .draw],
        awayForm: [.loss, .win, .loss, .draw, .win],
        homeWinPct: 80,
        awayWinPct: 40,
        homeOdds: "3/1",
        drawOdds: "4/1",
        awayOdds: "14/1"
    )

    static func from(fixture: Fixture) -> MatchStats {
        MatchStats(
            homeForm: placeholder.homeForm,
            awayForm: placeholder.awayForm,
            homeWinPct: fixture.homeWinProb.map {
                Int($0 * 100)
            } ?? placeholder.homeWinPct,
            awayWinPct: fixture.awayWinProb.map {
                Int($0 * 100)
            } ?? placeholder.awayWinPct,
            homeOdds: fractionalOdds(
                from: fixture.homeWinProb
            ),
            drawOdds: fractionalOdds(
                from: fixture.drawProb
            ),
            awayOdds: fractionalOdds(
                from: fixture.awayWinProb
            )
        )
    }

    private static func fractionalOdds(
        from probability: Double?
    ) -> String {
        guard let prob = probability,
              prob > 0 else { return "—" }
        let decimal = 1.0 / prob
        let profit = decimal - 1.0

        let commonDenominators = [1, 2, 4, 5, 10, 20]
        var bestNum = Int(profit.rounded())
        var bestDen = 1
        var bestError = Double.infinity

        for den in commonDenominators {
            let num = Int((profit * Double(den)).rounded())
            guard num > 0 else { continue }
            let error = abs(
                profit - Double(num) / Double(den)
            )
            if error < bestError {
                bestError = error
                bestNum = num
                bestDen = den
            }
        }
        return "\(bestNum)/\(bestDen)"
    }
}

// MARK: - Stats Panel View

struct MatchStatsPanel: View {
    let fixture: Fixture
    let stats: MatchStats

    var body: some View {
        ZStack(alignment: .top) {
            statsContent
            topGradient
        }
    }

    // fill_4YPJOB: linear-gradient(180deg, #241E31 0%,
    // transparent 100%), height 109px (layout_MGV8OU)
    private var topGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "241E31"),
                Color(hex: "241E31").opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 109)
    }
}

// MARK: - Stats Content

extension MatchStatsPanel {
    private var statsContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            teamHeaders
            Spacer().frame(height: 24)
            formSection
            Spacer().frame(height: 24)
            oddsSection
        }
        .padding(.horizontal, 24)
    }

    // style_N4653T: Inter Bold 16, uppercase, center,
    // white 40%
    private var teamHeaders: some View {
        HStack {
            Text(fixture.homeTeamName.uppercased())
                .font(Theme.Typography.subhead)
                .foregroundStyle(Color.white)
                .opacity(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            // stroke_31DNTO: rgba(255,255,255,0.2), 1px
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 20)

            Text(fixture.awayTeamName.uppercased())
                .font(Theme.Typography.subhead)
                .foregroundStyle(Color.white)
                .opacity(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Form Section

extension MatchStatsPanel {
    // style_76IR83: Inter Bold 12, uppercase, center,
    // white 40%
    private var formSection: some View {
        VStack(spacing: 12) {
            Text("FORM")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .opacity(0.4)

            HStack {
                formColumn(
                    results: stats.homeForm,
                    winPct: stats.homeWinPct
                )
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 50)
                formColumn(
                    results: stats.awayForm,
                    winPct: stats.awayWinPct
                )
            }
        }
    }

    private func formColumn(
        results: [FormResult],
        winPct: Int
    ) -> some View {
        VStack(spacing: 8) {
            // Win/loss dots: 20×20 circles
            HStack(spacing: 4) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                    Circle()
                        .fill(result.color)
                        .frame(width: 20, height: 20)
                }
            }
            Text("\(winPct)% WIN")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .opacity(0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Odds Section

extension MatchStatsPanel {
    // layout_3A62O5: row, center, hug
    // layout_6YA27N: 79px wide, padding 8px, radius 12px
    // stroke_31DNTO: 1px rgba(255,255,255,0.2)
    private var oddsSection: some View {
        VStack(spacing: 12) {
            Text("ODDS")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .opacity(0.4)

            HStack(spacing: 0) {
                oddsBox(label: "HOME", value: stats.homeOdds)
                oddsSeparator
                oddsBox(label: "DRAW", value: stats.drawOdds)
                oddsSeparator
                oddsBox(label: "AWAY", value: stats.awayOdds)
            }
        }
    }

    private func oddsBox(
        label: String,
        value: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .opacity(0.4)
            Text(value)
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .opacity(0.4)
        }
        .frame(width: 79)
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color.white.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    // layout_ZS9FZ1: 48px wide separator line
    private var oddsSeparator: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 48, height: 1)
    }
}
