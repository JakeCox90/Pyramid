#if DEBUG
import SwiftUI

struct EmptyStateDemo: View {
    @State private var title = "No Leagues Yet"
    @State private var message =
        "Join or create a league to get started."
    @State private var buttonTitle = "Create League"
    @State private var showButton = true

    var body: some View {
        DemoPage {
            PlaceholderView(
                icon: Theme.Icon.League.trophy,
                title: title,
                message: message,
                buttonTitle: showButton
                    ? buttonTitle : nil,
                onAction: showButton ? {} : nil
            )
        } config: {
            ConfigRow(label: "Title") {
                TextField("Title", text: $title)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Message") {
                TextField("Message", text: $message)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Show Button") {
                Toggle("", isOn: $showButton)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Button Title") {
                TextField(
                    "Button", text: $buttonTitle
                )
                .multilineTextAlignment(.trailing)
                .font(Theme.Typography.body)
                .opacity(showButton ? 1 : 0.4)
            }
        }
    }
}

struct ToastDemo: View {
    @State private var style: FlagVariant = .success
    @State private var title = "Achievement Unlocked"
    @State private var subtitle =
        "You earned a new badge"
    @State private var showSubtitle = true

    var body: some View {
        DemoPage {
            Toast(config: ToastConfiguration(
                icon: style == .success
                    ? "trophy.fill"
                    : "exclamationmark.triangle",
                title: title,
                subtitle: showSubtitle
                    ? subtitle : nil,
                style: style
            ))
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
            ConfigRow(label: "Title") {
                TextField("Title", text: $title)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Subtitle") {
                Toggle("", isOn: $showSubtitle)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Subtitle Text") {
                TextField(
                    "Subtitle", text: $subtitle
                )
                .multilineTextAlignment(.trailing)
                .font(Theme.Typography.body)
                .opacity(showSubtitle ? 1 : 0.4)
            }
        }
    }
}

struct DetailSheetDemo: View {
    @State private var iconStyle: FlagVariant =
        .warning
    @State private var title = "Iron Wall"
    @State private var subtitle =
        "Survive 5 consecutive gameweeks"
    @State private var showBody = true

    var body: some View {
        DemoPage {
            DetailSheet(
                config: DetailSheetConfiguration(
                    icon: "flame.fill",
                    iconStyle: iconStyle,
                    title: title,
                    subtitle: subtitle,
                    metadata: [
                        (
                            "Unlocked",
                            "March 23, 2026"
                        ),
                        ("League", "Office League")
                    ],
                    body: showBody
                        ? "You survived 5 gameweeks in a row."
                        : nil
                )
            )
        } config: {
            ConfigRow(label: "Icon Style") {
                Picker("", selection: $iconStyle) {
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
            ConfigRow(label: "Title") {
                TextField("Title", text: $title)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Subtitle") {
                TextField(
                    "Subtitle", text: $subtitle
                )
                .multilineTextAlignment(.trailing)
                .font(Theme.Typography.body)
            }
            ConfigDivider()
            ConfigRow(label: "Show Body") {
                Toggle("", isOn: $showBody)
                    .labelsHidden()
            }
        }
    }
}
#endif
