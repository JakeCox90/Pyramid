import SwiftUI

struct LeagueCreatedView: View {
    let response: CreateLeagueResponse
    let onDone: () -> Void

    @State private var didCopy = false

    private var shareText: String {
        "Join my Last Man Standing league \"\(response.name)\"! Use code: \(response.joinCode)"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s70) {
            Spacer()

            Image(systemName: Theme.Icon.League.trophyFill)
                .font(.system(size: 56))
                .foregroundStyle(Theme.Color.Primary.resting)

            VStack(spacing: Theme.Spacing.s20) {
                Text("League Created!")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text(response.name)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }

            DSCard {
                VStack(spacing: Theme.Spacing.s30) {
                    Text("Join Code")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(response.joinCode)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Color.Primary.resting)
                        .tracking(8)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Share this code with friends so they can join")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)

            HStack(spacing: Theme.Spacing.s30) {
                Button {
                    UIPasteboard.general.string = response.joinCode
                    didCopy = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        didCopy = false
                    }
                } label: {
                    Label(
                        didCopy ? "Copied!" : "Copy Code",
                        systemImage: didCopy ? Theme.Icon.Action.copied : Theme.Icon.Action.copy
                    )
                }
                .dsStyle(.secondary, fullWidth: false)

                ShareLink(item: shareText) {
                    Label("Share", systemImage: Theme.Icon.Action.share)
                }
                .buttonStyle(DSButtonStyle(variant: .secondary, size: .large, isFullWidth: false))
            }
            .padding(.horizontal, Theme.Spacing.s40)

            Button("Done") { onDone() }
                .dsStyle(.primary)
                .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
    }
}
