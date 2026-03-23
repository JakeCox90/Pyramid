import SwiftUI

#if DEBUG
extension ProfileView {
    func resetButton(
        title: String,
        subtitle: String,
        isLoading: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.body)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    Text(subtitle)
                        .font(Theme.Typography.overline)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                }
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                }
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
        .buttonStyle(.plain)
        .disabled(isResettingGame || isResettingFull)
    }

    func performReset(mode: String) async {
        let isFull = mode == "full"
        if isFull {
            isResettingFull = true
        } else {
            isResettingGame = true
        }
        resetMessage = nil

        do {
            let client = SupabaseDependency.shared.client
            let response = try await DevResetService.reset(
                mode: mode,
                client: client
            )

            if response.clearOnboarding {
                appState.resetToOnboarding()
            }

            resetMessage = "Reset complete (\(mode))"
        } catch {
            Log.auth.error(
                "DevReset failed: \(error.localizedDescription)"
            )
            resetMessage =
                "Reset failed: \(error.localizedDescription)"
        }

        if isFull {
            isResettingFull = false
        } else {
            isResettingGame = false
        }
    }
}
#endif
