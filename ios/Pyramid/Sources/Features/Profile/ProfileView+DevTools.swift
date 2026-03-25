#if DEBUG
import SwiftUI

// MARK: - Developer Tools

extension ProfileView {
    var devToolsSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text("Developer Tools")
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            gameweekPhaseControl
            paidFeaturesToggle
            designSystemLink

            devToolButton(
                title: "Gameweek Recap",
                subtitle:
                    "Preview end-of-gameweek story",
                icon: "book.pages"
            ) {
                showGameweekStory = true
            }

            resetButton(
                title: "Reset Game Data",
                subtitle:
                    "Re-seeds leagues, picks & fixtures",
                isLoading: isResettingGame,
                action: {
                    await performReset(mode: "game")
                }
            )

            resetButton(
                title: "Reset Everything",
                subtitle:
                    "Game data + restart onboarding",
                isLoading: isResettingFull,
                action: {
                    await performReset(mode: "full")
                }
            )

            if let resetMessage {
                Text(resetMessage)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    var gameweekPhaseControl: some View {
        VStack(
            alignment: .leading,
            spacing: Theme.Spacing.s10
        ) {
            Text("Gameweek Status")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Picker(
                "Gameweek Phase",
                selection: $gameweekPhase
            ) {
                ForEach(
                    DebugGameweekOverride.Phase
                        .allCases,
                    id: \.self
                ) { phase in
                    Text(phase.rawValue).tag(phase)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: gameweekPhase) { phase in
                DebugGameweekOverride.current = phase
            }
            Text(
                gameweekPhase == .none
                    ? "Using real API data"
                    : "Overriding gameweek state"
            )
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
        )
    }

    var paidFeaturesToggle: some View {
        Toggle(isOn: $paidFeaturesOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Paid Features")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .default
                    )
                Text(
                    paidFeaturesOn
                        ? "Wallet & paid leagues visible"
                        : "Free leagues only"
                )
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
            }
        }
        .tint(Theme.Color.Primary.resting)
        .onChange(of: paidFeaturesOn) { enabled in
            FeatureFlags.setPaidFeaturesOverride(
                enabled
            )
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
        )
    }

    var designSystemLink: some View {
        NavigationLink(
            destination: DesignSystemBrowserView()
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Design System")
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text
                                .default
                        )
                    Text(
                        "Browse tokens & components"
                    )
                    .font(Theme.Typography.overline)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .subtle
                    )
                }
                Spacer()
                Image(
                    systemName: "paintpalette"
                )
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
            }
            .padding(Theme.Spacing.s30)
            .background(
                Theme.Color.Surface.Background
                    .container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius
                        .default
                )
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
