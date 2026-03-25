#if DEBUG
import SwiftUI

struct AvatarDemo: View {
    @State private var name = "Jake Cox"
    @State private var size: AvatarSize = .large

    var body: some View {
        DemoPage {
            Avatar(name: name, size: size)
        } config: {
            ConfigRow(label: "Size") {
                Picker("", selection: $size) {
                    Text("small")
                        .tag(AvatarSize.small)
                    Text("medium")
                        .tag(AvatarSize.medium)
                    Text("large")
                        .tag(AvatarSize.large)
                }
            }
            ConfigDivider()
            ConfigRow(label: "Name") {
                TextField("Name", text: $name)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
        }
    }
}

struct PulsingDotDemo: View {
    var body: some View {
        DemoPageStatic {
            HStack(spacing: Theme.Spacing.s20) {
                PulsingDot()
                Text("Live indicator")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .default
                    )
            }
        }
    }
}

struct TeamBadgeDemo: View {
    @State private var teamName = "Arsenal"
    @State private var size: CGFloat = 64

    var body: some View {
        DemoPage {
            TeamBadge(
                teamName: teamName,
                logoURL: nil,
                size: size
            )
        } config: {
            ConfigRow(label: "Team Name") {
                TextField("Name", text: $teamName)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(
                label: "Size (\(Int(size))pt)"
            ) {
                Slider(
                    value: $size,
                    in: 24...140,
                    step: 4
                )
                .frame(width: 140)
            }
        }
    }
}

struct TeamsUsedPillDemo: View {
    @State private var count = 3

    private let allTeams = [
        "Arsenal", "Chelsea", "Liverpool",
        "Tottenham", "Man City", "Everton",
        "Man Utd", "Newcastle"
    ]

    var body: some View {
        DemoPage {
            TeamsUsedPill(
                teamNames: Array(
                    allTeams.prefix(count)
                ),
                count: count
            )
        } config: {
            ConfigRow(
                label: "Teams Used (\(count))"
            ) {
                Stepper(
                    "",
                    value: $count,
                    in: 0...allTeams.count
                )
                .labelsHidden()
            }
        }
    }
}

struct IconBadgeDemo: View {
    @State private var style: FlagVariant = .success
    @State private var isActive = true
    @State private var label = "Survivor"
    @State private var tier = 1

    var body: some View {
        DemoPage {
            IconBadge(
                config: IconBadgeConfiguration(
                    icon: isActive
                        ? "shield.fill"
                        : "lock.fill",
                    label: label,
                    isActive: isActive,
                    tier: isActive ? tier : nil,
                    style: style
                )
            )
        } config: {
            ConfigRow(label: "Style") {
                Picker("", selection: $style) {
                    Text("success")
                        .tag(FlagVariant.success)
                    Text("error")
                        .tag(FlagVariant.error)
                    Text("neutral")
                        .tag(FlagVariant.neutral)
                    Text("warning")
                        .tag(FlagVariant.warning)
                }
            }
            ConfigDivider()
            ConfigRow(label: "Active") {
                Toggle("", isOn: $isActive)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Label") {
                TextField("Label", text: $label)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Tier (\(tier))") {
                Stepper(
                    "",
                    value: $tier,
                    in: 1...5
                )
                .labelsHidden()
            }
        }
    }
}
#endif
