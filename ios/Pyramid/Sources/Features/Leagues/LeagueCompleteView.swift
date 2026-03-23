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
                .font(Theme.Typography.h3)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .multilineTextAlignment(.center)

            Text("League Complete")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
        .frame(maxWidth: .infinity)
    }

    private var winnersSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text(winners.count == 1 ? "Winner" : "Joint Winners")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(winners) { winner in
                Card {
                    HStack(spacing: Theme.Spacing.s30) {
                        winnerAvatar(winner)

                        Text(winner.profiles.displayLabel)
                            .font(Theme.Typography.subhead)
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )

                        Spacer()

                        Text("Winner")
                            .font(Theme.Typography.overline)
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
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            Card {
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

    @ViewBuilder
    private func winnerAvatar(_ member: LeagueMember) -> some View {
        let size: CGFloat = 36
        ZStack(alignment: .bottomTrailing) {
            if let urlString = member.profiles.avatarUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        winnerAvatarFallback(member, size: size)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                winnerAvatarFallback(member, size: size)
            }
            Image(systemName: Theme.Icon.League.trophyFill)
                .font(.system(size: 10))
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
                .offset(x: 2, y: 2)
        }
    }

    private func winnerAvatarFallback(
        _ member: LeagueMember,
        size: CGFloat
    ) -> some View {
        Text(member.profiles.displayLabel.prefix(1).uppercased())
            .font(Theme.Typography.subhead)
            .foregroundStyle(Theme.Color.Content.Text.subtle)
            .frame(width: size, height: size)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(Circle())
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
            Spacer()
            Text(value)
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }
}
