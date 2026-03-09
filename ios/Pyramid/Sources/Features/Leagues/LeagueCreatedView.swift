import SwiftUI

struct LeagueCreatedView: View {
    let response: CreateLeagueResponse
    let onDone: () -> Void

    @State private var didCopy = false

    private var shareText: String {
        "Join my Last Man Standing league \"\(response.name)\"! Use code: \(response.joinCode)"
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s8) {
            Spacer()

            Image(systemName: SFSymbol.trophyFill)
                .font(.system(size: 56))
                .foregroundStyle(Color.DS.Brand.primary)

            VStack(spacing: DS.Spacing.s2) {
                Text("League Created!")
                    .font(.DS.title1)
                    .foregroundStyle(Color.DS.Neutral.n900)

                Text(response.name)
                    .font(.DS.headline)
                    .foregroundStyle(Color.DS.Neutral.n700)
            }

            DSCard {
                VStack(spacing: DS.Spacing.s3) {
                    Text("Join Code")
                        .font(.DS.caption1)
                        .foregroundStyle(Color.DS.Neutral.n500)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text(response.joinCode)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.DS.Brand.primary)
                        .tracking(8)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Share this code with friends so they can join")
                        .font(.DS.caption1)
                        .foregroundStyle(Color.DS.Neutral.n500)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)

            HStack(spacing: DS.Spacing.s3) {
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
                        systemImage: didCopy ? SFSymbol.copyConfirmed : SFSymbol.copyToClipboard
                    )
                }
                .dsStyle(.secondary, fullWidth: false)

                ShareLink(item: shareText) {
                    Label("Share", systemImage: SFSymbol.share)
                }
                .buttonStyle(DSButtonStyle(variant: .secondary, size: .large, isFullWidth: false))
            }
            .padding(.horizontal, DS.Spacing.pageMargin)

            Button("Done") { onDone() }
                .dsStyle(.primary)
                .padding(.horizontal, DS.Spacing.pageMargin)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.DS.Background.primary.ignoresSafeArea())
    }
}
