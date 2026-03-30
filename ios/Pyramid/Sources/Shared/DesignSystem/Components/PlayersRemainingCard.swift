import SwiftUI

struct PlayersRemainingCard: View {
    let playerCount: PlayerCount
    let onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s30
            ) {
                headerRow
                progressionBar
                contextLabel
            }
            .padding(Theme.Spacing.s40)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r50
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                    .accessibilityHidden(true)
                Text("Players Remaining")
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
            Spacer()
            HStack(
                alignment: .firstTextBaseline,
                spacing: 2
            ) {
                Text("\(playerCount.active)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Text("/ \(playerCount.total)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
        }
    }

    // MARK: - Progression Bar

    private var progressionBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segment.color)
                        .frame(
                            width: segmentWidth(
                                count: segment.count,
                                totalWidth: geo.size.width
                            )
                        )
                }
            }
        }
        .frame(height: 8)
        .animation(
            .easeInOut(duration: 0.4),
            value: playerCount.active
        )
    }

    // MARK: - Context Label

    private var contextLabel: some View {
        Group {
            if let latestElim = latestEliminationText {
                Text(latestElim)
            } else {
                Text(percentageText)
            }
        }
        .font(Theme.Typography.overline)
        .foregroundStyle(
            Theme.Color.Content.Text.disabled
        )
    }

    // MARK: - Computed

    private var percentageText: String {
        guard playerCount.total > 0 else { return "" }
        let pct = Int(
            round(
                Double(playerCount.active)
                / Double(playerCount.total) * 100
            )
        )
        return "You're in the final \(pct)%"
    }

    private var latestEliminationText: String? {
        guard let latest = playerCount.eliminationHistory.last,
              latest.eliminated > 0
        else { return nil }
        let plural = latest.eliminated == 1
            ? "player" : "players"
        return "\(latest.eliminated) \(plural) eliminated in GW\(latest.gameweekId)"
    }

    private var accessibilityText: String {
        "\(playerCount.active) of \(playerCount.total) players remaining. \(percentageText). Tap to view standings."
    }

    // MARK: - Segments

    private struct BarSegment: Identifiable {
        let id: String
        let count: Int
        let color: Color
    }

    private var segments: [BarSegment] {
        var result: [BarSegment] = []

        for snapshot in playerCount.eliminationHistory {
            result.append(
                BarSegment(
                    id: "elim-\(snapshot.gameweekId)",
                    count: snapshot.eliminated,
                    color: Theme.Color.Status.Error.resting
                        .opacity(0.4)
                )
            )
        }

        if playerCount.active > 0 {
            result.append(
                BarSegment(
                    id: "active",
                    count: playerCount.active,
                    color: Theme.Color.Status.Success.resting
                )
            )
        }

        return result
    }

    private func segmentWidth(
        count: Int, totalWidth: CGFloat
    ) -> CGFloat {
        guard playerCount.total > 0 else { return 0 }
        let spacing = CGFloat(
            max(0, segments.count - 1)
        ) * 2
        let available = totalWidth - spacing
        return max(
            2,
            available * CGFloat(count) / CGFloat(
                playerCount.total
            )
        )
    }
}
