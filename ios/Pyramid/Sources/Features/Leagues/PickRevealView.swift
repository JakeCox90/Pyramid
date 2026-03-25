import SwiftUI

// MARK: - Pick Reveal View

/// Full-screen reveal of all league members' picks with a staggered
/// card-flip animation. Only shown after the gameweek deadline (§3.5).
struct PickRevealView: View {
    let members: [LeagueMember]
    let picks: [String: MemberPick]
    let fixtures: [Int: Fixture]

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var revealedIndices: Set<Int> = []
    @State private var hasStartedReveal = false

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.s30),
        GridItem(.flexible(), spacing: Theme.Spacing.s30)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s40) {
                    headerText
                    pickGrid
                }
                .padding(.horizontal, Theme.Spacing.s40)
                .padding(.vertical, Theme.Spacing.s40)
            }
            .background(
                Theme.Color.Surface.Background.page
                    .ignoresSafeArea()
            )
            .navigationTitle("Pick Reveal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { startStaggeredReveal() }
        }
    }

    // MARK: - Subviews

    private var headerText: some View {
        Text("Picks are in!")
            .font(Theme.Typography.h3)
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pickGrid: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.s30) {
            ForEach(
                Array(members.enumerated()),
                id: \.element.id
            ) { index, member in
                let pick = picks[member.userId]
                let fixture = pick.flatMap { fixtures[$0.fixtureId] }
                PickRevealCard(
                    member: member,
                    pick: pick,
                    fixture: fixture,
                    isRevealed: revealedIndices.contains(index)
                )
            }
        }
    }

    // MARK: - Animation

    private func startStaggeredReveal() {
        guard !hasStartedReveal else { return }
        hasStartedReveal = true

        if reduceMotion {
            revealedIndices = Set(0..<members.count)
            return
        }

        for index in members.indices {
            let delay = Double(index) * 0.12
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.3 + delay
            ) {
                withAnimation(
                    .spring(
                        response: 0.5,
                        dampingFraction: 0.85
                    )
                ) {
                    _ = revealedIndices.insert(index)
                }
            }
        }
    }
}

// MARK: - Pick Reveal Card

struct PickRevealCard: View {
    let member: LeagueMember
    let pick: MemberPick?
    let fixture: Fixture?
    let isRevealed: Bool

    private let badgeSize: CGFloat = 48
    private let avatarSize: CGFloat = 32

    var body: some View {
        ZStack {
            backFace
                .rotation3DEffect(
                    .degrees(isRevealed ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isRevealed ? 1 : 0)

            frontFace
                .rotation3DEffect(
                    .degrees(isRevealed ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isRevealed ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }

    // MARK: - Front Face (hidden pick)

    private var frontFace: some View {
        Card {
            VStack(spacing: Theme.Spacing.s20) {
                avatarView
                Text(member.profiles.displayLabel)
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .lineLimit(1)
                Image(systemName: Theme.Icon.Pick.locked)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Border.default
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Back Face (revealed pick)

    private var backFace: some View {
        Card {
            VStack(spacing: Theme.Spacing.s20) {
                if let pick {
                    teamBadge(for: pick)
                    Text(pick.teamName)
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Image(
                        systemName: "questionmark.circle"
                    )
                    .font(.system(size: badgeSize))
                    .foregroundStyle(
                        Theme.Color.Border.default
                    )
                    Text("No pick")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(
                            Theme.Color.Content.Text.disabled
                        )
                }
                memberLabel
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func teamBadge(for pick: MemberPick) -> some View {
        let logoURL = teamLogoURL(for: pick)
        TeamBadge(
            teamName: pick.teamName,
            logoURL: logoURL,
            size: badgeSize
        )
    }

    private func teamLogoURL(
        for pick: MemberPick
    ) -> String? {
        guard let fixture else { return nil }
        if pick.teamId == fixture.homeTeamId {
            return fixture.homeTeamLogo
        } else if pick.teamId == fixture.awayTeamId {
            return fixture.awayTeamLogo
        }
        return nil
    }

    private var memberLabel: some View {
        HStack(spacing: Theme.Spacing.s10) {
            avatarView
                .scaleEffect(0.6)
                .frame(width: 20, height: 20)
            Text(member.profiles.displayLabel)
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .lineLimit(1)
        }
    }

    @ViewBuilder private var avatarView: some View {
        if let urlString = member.profiles.avatarUrl,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    avatarFallback
                @unknown default:
                    avatarFallback
                }
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
        } else {
            avatarFallback
        }
    }

    private var avatarFallback: some View {
        Text(
            member.profiles.displayLabel
                .prefix(1).uppercased()
        )
        .font(Theme.Typography.overline)
        .foregroundStyle(
            Theme.Color.Content.Text.subtle
        )
        .frame(width: avatarSize, height: avatarSize)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(Circle())
    }
}
