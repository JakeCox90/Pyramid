import SwiftUI

// Figma: Match Card
// Variant=Fixture (32:4241), Variant=Result (32:4240),
// Variant=Empty (32:4432)
// 345–370×446, border-radius 24px
// Pre-match gradient: 225deg, #5E4E81 0% → #2D253D 72%
// Result gradient: 225deg, #4E815B 0% → #2D253D 72%

// MARK: - Match Card

struct MatchCard: View {
    /// The card has three visual states driven by fixture status,
    /// not by the presence of score data.
    enum Phase {
        /// Pre-match: purple gradient, VS, venue/kickoff, CTA
        case preMatch
        /// Live: green gradient, score, LIVE pill, locked
        case live
        /// Finished: purple gradient, score, FT pill, locked
        case finished

        // MARK: - Colour Config

        /// 225° gradient start — green for live, purple otherwise
        var gradientStart: Color {
            switch self {
            case .live:
                Theme.Color.Match.Gradient.liveStart
            case .preMatch, .finished:
                Theme.Color.Match.Gradient.purpleStart
            }
        }

        /// 225° gradient end — shared across all phases
        var gradientEnd: Color {
            Theme.Color.Match.Gradient.purpleEnd
        }

        /// VS circle fill (pre-match only)
        var vsCircleFill: Color {
            Theme.Color.Surface.Background.elevated
        }

        /// Half-tint overlay
        var halfTint: Color {
            Theme.Color.Surface.Background.card
        }

        /// Positive pill background (live dot, survived)
        var pillPositive: Color {
            Theme.Color.Match.Pill.positive
        }

        /// Negative pill background (eliminated)
        var pillNegative: Color {
            Theme.Color.Match.Pill.negative
        }
    }

    let pickedTeamName: String
    let pickedTeamLogo: String?
    let opponentName: String
    let homeTeamName: String
    var venue: String?
    var kickoff: Date?
    var homeScore: Int?
    var awayScore: Int?
    var phase: Phase = .preMatch
    /// For finished phase: true = survived, false = eliminated, nil = pending
    var survived: Bool?
    var isLocked: Bool = false
    var buttonTitle: String = "CHANGE PICK"
    var onButtonTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .top) {
            background
            halfTint
            switch phase {
            case .preMatch:
                preMatchContent
            case .live, .finished:
                resultContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 446)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Pre-Match Layout

private extension MatchCard {
    var preMatchContent: some View {
        VStack(spacing: 0) {
            badge
            Spacer().frame(height: 12)
            yourPickLabel
            Spacer().frame(height: 4)
            pickedTeamTitle
            Spacer().frame(height: 12)
            vsDivider
            Spacer().frame(height: 12)
            opponentTitle
            Spacer().frame(height: 8)
            fixtureDetails
            Spacer()
            bottomSection
        }
    }

    var vsDivider: some View {
        HStack(alignment: .center, spacing: 0) {
            dividerLine
            ZStack {
                Circle()
                    .fill(phase.vsCircleFill)
                Circle()
                    .stroke(
                        Theme.Color.Border.default,
                        lineWidth: 1
                    )
                Text("VS")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
            .frame(width: 40, height: 40)
            dividerLine
        }
    }

    var fixtureDetails: some View {
        VStack(spacing: 3) {
            if let venue {
                Text(venue)
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        Theme.Color.Content.Text.muted
                    )
            }
            if let kickoff {
                Text(
                    Self.kickoffLabel(kickoff)
                )
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.muted
                )
            }
        }
    }
}

// MARK: - Shared Subviews

extension MatchCard {
    var background: some View {
        LinearGradient(
            stops: [
                .init(
                    color: phase.gradientStart,
                    location: 0.0
                ),
                .init(
                    color: phase.gradientEnd,
                    location: 0.72
                )
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Figma: y=-30, 277×132, radius 0/0/200/200
    /// Flat top, rounded bottom — offset upward 30px
    var halfTint: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 200,
            bottomTrailingRadius: 200,
            topTrailingRadius: 0
        )
        .fill(phase.halfTint.opacity(0.4))
        .frame(width: 277, height: 132)
        .offset(y: -30)
    }

    var badge: some View {
        TeamBadge(
            teamName: pickedTeamName,
            logoURL: pickedTeamLogo,
            size: 140
        )
        .shadow(
            color: .black.opacity(0.4),
            radius: 12, x: 0, y: 4
        )
        .padding(.top, 12)
    }

    var yourPickLabel: some View {
        Text("YOUR PICK")
            .font(Theme.Typography.overline)
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
    }

    var pickedTeamTitle: some View {
        Text(pickedTeamName)
            .font(Theme.Typography.h2)
            .foregroundStyle(Theme.Color.Content.Text.default)
    }

    var opponentTitle: some View {
        Text(opponentName)
            .font(Theme.Typography.h3)
            .foregroundStyle(Theme.Color.Content.Text.default)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(Theme.Color.Border.default)
            .frame(height: 1)
    }

    /// Locked pill: themed disabled button with lock icon
    var lockedPill: some View {
        Button {} label: {
            Label(
                "LOCKED",
                systemImage: Theme.Icon.Pick.locked
            )
        }
        .themed(.secondary)
        .disabled(true)
    }

    @ViewBuilder var bottomSection: some View {
        if isLocked {
            lockedPill
                .padding(.horizontal, 24)
                .padding(.bottom, Theme.Spacing.s60)
        } else if let onButtonTap {
            Button(buttonTitle, action: onButtonTap)
                .themed(.secondary)
                .padding(
                    .horizontal, Theme.Spacing.s60
                )
                .padding(
                    .bottom, Theme.Spacing.s60
                )
        }
    }
}

// MARK: - Helpers

extension MatchCard {
    var scoreText: String {
        "\(homeScore ?? 0) - \(awayScore ?? 0)"
    }

    static func kickoffLabel(
        _ date: Date
    ) -> String {
        let formatter = DateFormatter()
        let day = Calendar.current.component(
            .day, from: date
        )
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "ST"
        case 2, 22:     suffix = "ND"
        case 3, 23:     suffix = "RD"
        default:        suffix = "TH"
        }
        formatter.dateFormat = "EEE d'\(suffix)', ha"
        return formatter.string(
            from: date
        ).uppercased()
    }
}
