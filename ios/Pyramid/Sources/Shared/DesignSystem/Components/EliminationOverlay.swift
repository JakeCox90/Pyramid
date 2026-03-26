import SwiftUI

/// Full-screen dramatic overlay shown when the user is first
/// notified of their elimination. Tap to dismiss.
struct EliminationOverlay: View {
    let leagueName: String
    let pickedTeamName: String
    let opponentName: String
    let homeScore: Int
    let awayScore: Int
    let pickedHome: Bool
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s40) {
                Spacer()

                skullIcon

                eliminatedTitle

                leagueLabel

                Spacer().frame(height: Theme.Spacing.s20)

                scoreDisplay

                pickDetail

                Spacer()

                dismissHint
            }
            .padding(.horizontal, Theme.Spacing.s60)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(
                .easeIn(duration: 0.6)
            ) {
                appeared = true
            }
        }
        .onTapGesture { onDismiss() }
    }
}

// MARK: - Subviews

private extension EliminationOverlay {
    var skullIcon: some View {
        Image(systemName: "xmark.seal.fill")
            .font(.system(size: 80))
            .foregroundStyle(Theme.Color.Content.Text.default)
            .shadow(
                color: .red.opacity(0.6),
                radius: 20
            )
            .scaleEffect(appeared ? 1.0 : 0.5)
            .animation(
                .spring(
                    response: 0.6,
                    dampingFraction: 0.6
                ),
                value: appeared
            )
    }

    var eliminatedTitle: some View {
        Text("YOU'VE BEEN\nELIMINATED")
            .font(Theme.Typography.h1)
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.Color.Content.Text.default)
            .offset(y: appeared ? 0 : 30)
            .animation(
                .easeOut(duration: 0.5)
                    .delay(0.2),
                value: appeared
            )
    }

    var leagueLabel: some View {
        Text(leagueName)
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Color.Content.Text.subtle)
    }

    var scoreDisplay: some View {
        HStack(spacing: Theme.Spacing.s30) {
            Text(pickedHome ? "YOU" : "OPP")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Text("\(homeScore)")
                .font(Theme.Typography.h1)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .monospacedDigit()
            Text("\u{2013}")
                .font(Theme.Typography.h2)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Text("\(awayScore)")
                .font(Theme.Typography.h1)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .monospacedDigit()
            Text(pickedHome ? "OPP" : "YOU")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
        .opacity(appeared ? 1 : 0)
        .animation(
            .easeIn(duration: 0.4).delay(0.4),
            value: appeared
        )
    }

    var pickDetail: some View {
        Text(
            "You picked \(pickedTeamName) vs \(opponentName)"
        )
        .font(Theme.Typography.label01)
        .foregroundStyle(Theme.Color.Content.Text.subtle)
        .multilineTextAlignment(.center)
        .opacity(appeared ? 1 : 0)
        .animation(
            .easeIn(duration: 0.4).delay(0.5),
            value: appeared
        )
    }

    var dismissHint: some View {
        Text("Tap anywhere to continue")
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Color.Content.Text.tertiary)
            .padding(.bottom, Theme.Spacing.s60)
            .opacity(appeared ? 1 : 0)
            .animation(
                .easeIn(duration: 0.4).delay(0.8),
                value: appeared
            )
    }

    var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(
                    color: Theme.Color.Elimination.gradientStart,
                    location: 0.0
                ),
                .init(
                    color: Theme.Color.Elimination.gradientEnd,
                    location: 0.7
                )
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
