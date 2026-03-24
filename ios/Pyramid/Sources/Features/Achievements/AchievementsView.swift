import SwiftUI

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    @State private var selectedBadge: AchievementsViewModel.DisplayBadge?

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Theme.Color.Surface.Background.page
                    .ignoresSafeArea()
            )
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await viewModel.loadAchievements() }
            .sheet(item: $selectedBadge) { badge in
                badgeDetail(badge)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        } else if let error = viewModel.errorMessage {
            PlaceholderView(
                icon: "exclamationmark.triangle",
                title: "Something went wrong",
                message: error
            )
        } else {
            badgeGrid
        }
    }

    private var badgeGrid: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s40
            ) {
                ForEach(
                    AchievementCatalog.tracks,
                    id: \.key
                ) { track in
                    trackSection(track)
                }

                singularSection
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s30)
        }
    }

    private func trackSection(
        _ track: (name: String, key: String)
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text(track.name)
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            let trackBadges = viewModel.displayBadges
                .filter { $0.definition.track == track.key }

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 80),
                        spacing: Theme.Spacing.s20
                    ),
                ],
                spacing: Theme.Spacing.s20
            ) {
                ForEach(trackBadges) { badge in
                    Button {
                        selectedBadge = badge
                    } label: {
                        IconBadge(
                            config: IconBadgeConfiguration(
                                icon: badge.isUnlocked
                                    ? badge.definition.icon
                                    : "lock.fill",
                                label: badge.isUnlocked
                                    ? badge.definition.name
                                    : "???",
                                isActive: badge.isUnlocked,
                                tier: badge.definition.tier,
                                style: badge.definition.style
                            ))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var singularSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Moments")
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            let singular = viewModel.displayBadges
                .filter { $0.definition.track == nil }

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 80),
                        spacing: Theme.Spacing.s20
                    ),
                ],
                spacing: Theme.Spacing.s20
            ) {
                ForEach(singular) { badge in
                    Button {
                        selectedBadge = badge
                    } label: {
                        IconBadge(
                            config: IconBadgeConfiguration(
                                icon: badge.isUnlocked
                                    ? badge.definition.icon
                                    : "lock.fill",
                                label: badge.isUnlocked
                                    ? badge.definition.name
                                    : "???",
                                isActive: badge.isUnlocked,
                                style: badge.definition.style
                            ))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func badgeDetail(
        _ badge: AchievementsViewModel.DisplayBadge
    ) -> some View {
        DetailSheet(config: DetailSheetConfiguration(
            icon: badge.definition.icon,
            iconStyle: badge.isUnlocked
                ? badge.definition.style
                : .neutral,
            title: badge.isUnlocked
                ? badge.definition.name
                : "???",
            subtitle: badge.isUnlocked
                ? badge.definition.description
                : "Keep playing to unlock this badge",
            metadata: badge.unlocked.map { achievement in
                [("Unlocked", achievement.unlockedAt
                    .formatted(
                        date: .abbreviated,
                        time: .omitted
                    ))]
            } ?? [],
            body: nil
        ))
    }
}
