import SwiftUI

struct LeagueCompleteView: View {
    @Environment(\.dismiss)
    private var dismiss

    let leagueName: String
    let winners: [LeagueMember]
    let totalMembers: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s60) {
                    trophySection
                    winnersSection
                    statsSection
                }
                .padding(.vertical, Theme.Spacing.s60)
                .padding(.horizontal, Theme.Spacing.s40)
            }
            .background(
                Theme.Color.Surface.Background.page.ignoresSafeArea()
            )
            .navigationTitle("Final Standings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var trophySection: some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: Theme.Icon.League.trophyFill)
                .font(.system(size: 72))
                .foregroundStyle(Theme.Color.Status.Warning.resting)

            Text(leagueName)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .multilineTextAlignment(.center)

            Text("League Complete")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
        .frame(maxWidth: .infinity)
    }

    private var winnersSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text(winners.count == 1 ? "Winner" : "Joint Winners")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(winners) { winner in
                DSCard {
                    HStack(spacing: Theme.Spacing.s30) {
                        Image(systemName: Theme.Icon.League.trophyFill)
                            .foregroundStyle(
                                Theme.Color.Status.Warning.resting
                            )

                        Text(winner.profiles.displayLabel)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )

                        Spacer()

                        Text("Winner")
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(
                                Theme.Color.Status.Warning.resting
                            )
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text("Summary")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            DSCard {
                VStack(spacing: Theme.Spacing.s30) {
                    statRow(
                        label: "Total Players",
                        value: "\(totalMembers)"
                    )
                    statRow(
                        label: winners.count == 1
                            ? "Winner"
                            : "Joint Winners",
                        value: "\(winners.count)"
                    )
                    statRow(
                        label: "Eliminated",
                        value: "\(totalMembers - winners.count)"
                    )
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
            Spacer()
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }
}
