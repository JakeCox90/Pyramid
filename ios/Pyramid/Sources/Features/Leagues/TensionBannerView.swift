import SwiftUI

struct TensionBannerView: View {
    let moments: [TensionMoment]

    var body: some View {
        VStack(spacing: Theme.Spacing.s20) {
            ForEach(moments) { moment in
                tensionCard(moment)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func tensionCard(
        _ moment: TensionMoment
    ) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 16))
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
                .accessibilityHidden(true)

            Text(bannerText(for: moment))
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Status.Warning.resting
                .opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.r30
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            accessibilityText(for: moment)
        )
    }

    private func bannerText(
        for moment: TensionMoment
    ) -> String {
        "\(moment.pickCount) players picked \(moment.teamName) — \(moment.flavorText)"
    }

    private func accessibilityText(
        for moment: TensionMoment
    ) -> String {
        "\(moment.pickCount) players picked \(moment.teamName), \(moment.flavorText)"
    }
}
