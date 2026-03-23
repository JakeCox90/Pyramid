#if DEBUG
import SwiftUI

enum ComponentTab: String, CaseIterable {
    case core = "Core"
    case match = "Match"
    case game = "Game"
}

struct ComponentBrowserView: View {
    @State private var selectedTab: ComponentTab = .core
    @State var sampleText = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("Group", selection: $selectedTab) {
                ForEach(
                    ComponentTab.allCases,
                    id: \.self
                ) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s20)

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s60
                ) {
                    switch selectedTab {
                    case .core:
                        coreContent
                    case .match:
                        matchContent
                    case .game:
                        gameContent
                    }
                }
                .padding(Theme.Spacing.s40)
            }
        }
    }
}

// MARK: - Core Tab

extension ComponentBrowserView {
    var coreContent: some View {
        Group {
            buttonsSection
            iconButtonsSection
            inputFieldsSection
            cardSection
            badgesSection
            placeholderSection
            pulsingDotSection
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
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
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

// MARK: - Card

private extension ComponentBrowserView {
    var cardSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "Card")

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
        }
    }
}

// MARK: - Badges

private extension ComponentBrowserView {
    var badgesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            ComponentHeader(title: "Badge")

            ComponentCaption(text: "Intents")
            HStack(spacing: Theme.Spacing.s20) {
                Badge(
                    label: "Success",
                    intent: .success
                )
                Badge(label: "Error", intent: .error)
                Badge(
                    label: "Neutral",
                    intent: .neutral
                )
                Badge(
                    label: "Warning",
                    intent: .warning
                )
            }

            ComponentCaption(
                text: "Pick status (domain mapping)"
            )
            HStack(spacing: Theme.Spacing.s20) {
                Badge(
                    label: PickStatus.survived.label,
                    intent: PickStatus.survived.badgeIntent
                )
                Badge(
                    label: PickStatus.eliminated.label,
                    intent: PickStatus.eliminated
                        .badgeIntent
                )
                Badge(
                    label: PickStatus.pending.label,
                    intent: PickStatus.pending.badgeIntent
                )
                Badge(
                    label: PickStatus.void.label,
                    intent: PickStatus.void.badgeIntent
                )
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
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
    }
}

struct ComponentCaption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
    }
}

#Preview {
    NavigationStack {
        ComponentBrowserView()
    }
}
#endif
