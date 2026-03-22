#if DEBUG
import SwiftUI

struct ComponentBrowserView: View {
    @State private var sampleText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s60) {
                buttonsSection
                iconButtonsSection
                inputFieldsSection
                cardsSection
                badgesSection
                placeholderSection
                pulsingDotSection
            }
            .padding(Theme.Spacing.s40)
        }
    }
}

// MARK: - Buttons

private extension ComponentBrowserView {
    var buttonsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "Button (.themed)")

            Button("Primary") {}
                .themed(.primary)
            Button("Secondary") {}
                .themed(.secondary)
            Button("Destructive") {}
                .themed(.destructive)
            Button("Ghost") {}
                .themed(.ghost)
            Button("Loading") {}
                .themed(.primary, isLoading: true)
            Button("Disabled") {}
                .themed(.primary)
                .disabled(true)
            Button("Compact") {}
                .themed(.primary, fullWidth: false)
        }
    }
}

// MARK: - Icon Buttons

private extension ComponentBrowserView {
    var iconButtonsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "IconButton")

            HStack(spacing: Theme.Spacing.s30) {
                IconButton(
                    icon: Theme.Icon.Navigation.add,
                    variant: .primary
                ) {}
                IconButton(
                    icon: Theme.Icon.Action.share,
                    variant: .secondary
                ) {}
                IconButton(
                    icon: Theme.Icon.Status.failure,
                    variant: .destructive
                ) {}
                IconButton(
                    icon: Theme.Icon.Navigation.notifications,
                    variant: .ghost
                ) {}
            }

            HStack(spacing: Theme.Spacing.s10) {
                Text("primary")
                Spacer()
                Text("secondary")
                Spacer()
                Text("destructive")
                Spacer()
                Text("ghost")
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
    }
}

// MARK: - Input Fields

private extension ComponentBrowserView {
    var inputFieldsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "InputField")

            InputField(
                label: "Default",
                text: $sampleText,
                placeholder: "Enter text..."
            )
            InputField(
                label: "With Error",
                text: .constant("Bad value"),
                placeholder: "Enter text...",
                errorMessage: "Invalid input"
            )
            InputField(
                label: "Secure",
                text: .constant(""),
                placeholder: "Password",
                isSecure: true
            )
        }
    }
}

// MARK: - Cards

private extension ComponentBrowserView {
    var cardsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "Card / LeagueCard")

            Card {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s20
                ) {
                    Text("Card")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    Text("Generic container with padding, background, radius, and shadow.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                }
            }

            LeagueCard(
                leagueName: "Sunday League",
                memberCount: 12,
                gameweek: 28,
                pickStatus: .survived
            )
            LeagueCard(
                leagueName: "Office Crew",
                memberCount: 8,
                gameweek: 28,
                pickStatus: .eliminated
            )
        }
    }
}

// MARK: - Badges

private extension ComponentBrowserView {
    var badgesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "PickStatusBadge")
            HStack(spacing: Theme.Spacing.s20) {
                PickStatusBadge(status: .survived)
                PickStatusBadge(status: .eliminated)
                PickStatusBadge(status: .pending)
                PickStatusBadge(status: .void)
            }
        }
    }
}

// MARK: - Placeholder

private extension ComponentBrowserView {
    var placeholderSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "PlaceholderView")

            ComponentCaption(
                text: "Empty state configuration"
            )
            PlaceholderView(
                icon: Theme.Icon.League.trophy,
                title: "No Leagues Yet",
                message: "Join or create a league to get started.",
                buttonTitle: "Create League",
                onAction: {}
            )
            .frame(height: 260)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )

            ComponentCaption(
                text: "Error state configuration"
            )
            PlaceholderView(
                icon: Theme.Icon.Status.error,
                title: "Something went wrong",
                message: "Failed to load data.",
                buttonTitle: "Try Again",
                onAsyncAction: {}
            )
            .frame(height: 260)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
        }
    }
}

// MARK: - Pulsing Dot

private extension ComponentBrowserView {
    var pulsingDotSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "PulsingDot")
            HStack(spacing: Theme.Spacing.s20) {
                PulsingDot()
                Text("Live indicator (respects reduce motion)")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
            }
            .padding(Theme.Spacing.s30)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r20
                )
            )
        }
    }
}

// MARK: - Helpers

struct ComponentHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.h3)
            .foregroundStyle(Theme.Color.Content.Text.default)
    }
}

struct ComponentCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Color.Content.Text.subtle)
    }
}

#Preview {
    NavigationStack {
        ComponentBrowserView()
    }
}
#endif
