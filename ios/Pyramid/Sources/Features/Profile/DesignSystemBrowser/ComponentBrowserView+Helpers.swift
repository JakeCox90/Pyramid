#if DEBUG
import SwiftUI

// MARK: - Shared Helpers

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

// MARK: - Config Controls

struct ConfigPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r20
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r20
            )
            .stroke(
                Theme.Color.Border.default,
                lineWidth: 1
            )
        )
    }
}

struct ConfigRow<Control: View>: View {
    let label: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
            control
                .tint(Theme.Color.Primary.resting)
        }
        .padding(.horizontal, Theme.Spacing.s30)
        .padding(.vertical, Theme.Spacing.s20)
    }
}

struct ConfigDivider: View {
    var body: some View {
        Divider()
            .background(Theme.Color.Border.default)
            .padding(.leading, Theme.Spacing.s30)
    }
}

// MARK: - Demo Preview Container

struct DemoPreview<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            content
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 240)
        .padding(Theme.Spacing.s40)
        .background(
            Theme.Color.Surface.Background.highlight
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
        )
    }
}

// MARK: - Split Demo Page

/// Top half: component preview. Bottom half: config.
struct DemoPage<Preview: View, Config: View>: View {
    @ViewBuilder let preview: () -> Preview
    @ViewBuilder let config: () -> Config

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView {
                    DemoPreview {
                        preview()
                    }
                    .padding(.horizontal, 16)
                    .padding(
                        .vertical,
                        Theme.Spacing.s40
                    )
                }
                .frame(height: geo.size.height * 0.5)

                Divider()
                    .background(
                        Theme.Color.Border.default
                    )

                ScrollView {
                    ConfigPanel {
                        config()
                    }
                    .padding(.horizontal, 16)
                    .padding(
                        .vertical,
                        Theme.Spacing.s30
                    )
                }
                .frame(height: geo.size.height * 0.5)
            }
        }
    }
}

/// Full-height preview for demos without config.
struct DemoPageStatic<Preview: View>: View {
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        ScrollView {
            DemoPreview {
                preview()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}
#endif
