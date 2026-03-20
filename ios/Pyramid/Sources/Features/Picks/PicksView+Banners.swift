import SwiftUI

// MARK: - Banners

extension PicksView {
    var bannerSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            if let pick = viewModel.currentPick {
                currentPickBanner(pick: pick)
            }
            if let success = viewModel.successMessage {
                successBanner(message: success)
                    .transition(
                        .move(edge: .top).combined(with: .opacity)
                    )
                    .animation(
                        reduceMotion
                            ? nil
                            : .spring(response: 0.4),
                        value: viewModel.successMessage
                    )
            }
            if let error = viewModel.errorMessage,
               !viewModel.fixtures.isEmpty {
                errorBanner(message: error)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func currentPickBanner(
        pick: Pick
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(
                systemName: pick.isLocked
                    ? Theme.Icon.Pick.locked
                    : Theme.Icon.Status.success
            )
            .foregroundStyle(
                pick.isLocked
                    ? Theme.Color.Content.Text.disabled
                    : Theme.Color.Status.Success.resting
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(
                    pick.isLocked
                        ? "Pick locked: \(pick.teamName)"
                        : "Current pick: \(pick.teamName)"
                )
                .font(Theme.Typography.subheadline.bold())
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                if !pick.isLocked {
                    Text(
                        "You can change your pick until kick-off."
                    )
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r30)
        )
    }

    private func successBanner(
        message: String
    ) -> some View {
        HStack {
            Image(systemName: Theme.Icon.Status.success)
                .foregroundStyle(
                    Theme.Color.Status.Success.resting
                )
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Status.Success.subtle)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r30)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private func errorBanner(
        message: String
    ) -> some View {
        HStack {
            Image(systemName: Theme.Icon.Status.errorFill)
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Status.Error.subtle)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r30)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
