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
    }

    let pickedTeamName: String
    let pickedTeamLogo: String?
    let opponentName: String
    let homeTeamName: String
    var venue: String?
    var kickoff: Date?
    var broadcast: String?
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
                    .fill(Color(hex: "3D3354"))
                Circle()
                    .stroke(
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
                Text("VS")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(.white)
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
                        Color.white.opacity(0.5)
                    )
            }
            if let kickoff {
                Text(
                    Self.kickoffLabel(kickoff)
                )
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Color.white.opacity(0.5)
                )
            }
            if let broadcast {
                Text(broadcast)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Color.white.opacity(0.3)
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
                    color: phase == .live
                        ? Color(hex: "4E815B")
                        : Color(hex: "5E4E81"),
                    location: 0.0
                ),
                .init(
                    color: Color(hex: "2D253D"),
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
        .fill(Color(hex: "241E31").opacity(0.4))
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
                Color.white.opacity(0.4)
            )
    }

    var pickedTeamTitle: some View {
        Text(pickedTeamName)
            .font(Theme.Typography.h2)
            .foregroundStyle(.white)
    }

    var opponentTitle: some View {
        Text(opponentName)
            .font(Theme.Typography.h3)
            .foregroundStyle(.white)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
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
