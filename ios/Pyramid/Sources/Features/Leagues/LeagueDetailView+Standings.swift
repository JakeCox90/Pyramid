import SwiftUI

// MARK: - Standings Content

extension LeagueDetailView {
    var standingsContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: Theme.Spacing.s40) {
                if viewModel.isCompleted {
                    winnerBanner
                }
                statsHeader
                tabPicker
            }
            .padding(.top, Theme.Spacing.s40)
            .padding(.bottom, Theme.Spacing.s20)

            tabContent
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Tabs(selected: $selectedTab)
    }

    // MARK: - Tab Content

    @ViewBuilder private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .myPicks:
            PickHistoryView(
                leagueId: viewModel.league.id
            )
        case .results:
            ResultsView(
                leagueId: viewModel.league.id,
                season: viewModel.league.season
            )
        }
    }

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s40) {
                if viewModel.currentGameweek != nil {
                    if viewModel.isRecapAvailable {
                        gwRecapButton
                    } else {
                        gwRecapUnavailable
                    }
                }
                myPickCard
                if viewModel.isCurrentUserEliminated {
                    spectatorBanner
                }
                if !viewModel.tensionMoments.isEmpty {
                    TensionBannerView(
                        moments: viewModel.tensionMoments
                    )
                }
                if viewModel.members.isEmpty {
                    emptyMembersView
                } else {
                    membersList
                }
                activitySection
                leaveLeagueButton
            }
            .padding(.vertical, Theme.Spacing.s20)
        }
    }

    var gwRecapButton: some View {
        Button {
            showStory = true
        } label: {
            HStack(spacing: Theme.Spacing.s20) {
                Image(systemName: "play.circle.fill")
                Text("GW Recap")
                    .font(Theme.Typography.body)
            }
            .foregroundStyle(Theme.Color.Accent.gold)
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s20)
            .background(
                Theme.Color.Accent.gold.opacity(0.1)
            )
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.s40)
        .accessibilityLabel("View gameweek recap")
    }

    var gwRecapUnavailable: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            HStack(spacing: Theme.Spacing.s20) {
                Image(systemName: "play.circle.fill")
                Text("GW Recap")
                    .font(Theme.Typography.body)
            }
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s20)
            .background(
                Theme.Color.Border.default.opacity(0.1)
            )
            .clipShape(Capsule())

            Text("Recap available after settlement")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.s40)
        .accessibilityLabel(
            "Gameweek recap not yet available"
        )
    }

    var emptyMembersView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.League.members)
                .font(.system(size: 48))
                .foregroundStyle(
                    Theme.Color.Border.default
                )
                .accessibilityHidden(true)
            Text("No other members yet")
                .font(Theme.Typography.subhead)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Text(
                "Share the join code to invite players."
            )
            .font(Theme.Typography.body)
            .foregroundStyle(
                Theme.Color.Content.Text.disabled
            )
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.top, Theme.Spacing.s70)
    }

    var membersList: some View {
        VStack(spacing: Theme.Spacing.s20) {
            if !viewModel.isDeadlinePassed() {
                HStack {
                    Image(
                        systemName: Theme.Icon.Pick.locked
                    )
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                    .accessibilityHidden(true)
                    Text(
                        "Picks are hidden until kick-off"
                    )
                    .font(Theme.Typography.overline)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.s40)
            } else {
                revealPicksButton
            }

            ForEach(viewModel.sortedMembers) { member in
                MemberRow(
                    member: member,
                    pick: viewModel.pick(for: member),
                    fixture: viewModel.pick(for: member)
                        .flatMap {
                            viewModel.fixture(for: $0)
                        },
                    deadlinePassed: viewModel
                        .isDeadlinePassed()
                )
                .padding(.horizontal, Theme.Spacing.s40)
            }
        }
    }

    var revealPicksButton: some View {
        Button {
            showPickReveal = true
        } label: {
            HStack(spacing: Theme.Spacing.s20) {
                Image(
                    systemName: "rectangle.stack.fill"
                )
                Text("Reveal All Picks")
                    .font(Theme.Typography.body)
            }
            .foregroundStyle(
                Theme.Color.Status.Success.resting
            )
            .padding(
                .horizontal, Theme.Spacing.s40
            )
            .padding(
                .vertical, Theme.Spacing.s20
            )
            .background(
                Theme.Color.Status.Success.resting
                    .opacity(0.1)
            )
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.s40)
        .accessibilityLabel("Reveal all members' picks")
    }

    var leaveLeagueButton: some View {
        Button {
            showLeaveConfirmation = true
        } label: {
            HStack(spacing: Theme.Spacing.s10) {
                Image(
                    systemName: "rectangle.portrait.and.arrow.right"
                )
                Text("Leave League")
                    .font(Theme.Typography.body)
            }
            .foregroundStyle(
                Theme.Color.Status.Error.resting
            )
        }
        .disabled(viewModel.isLeaving)
        .padding(.top, Theme.Spacing.s40)
        .accessibilityLabel("Leave this league")
    }
}
