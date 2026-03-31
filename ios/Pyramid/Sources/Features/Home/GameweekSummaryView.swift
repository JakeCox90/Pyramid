import SwiftUI

/// Full-screen overlay with a horizontal card carousel showing
/// the user's gameweek results across all leagues.
struct GameweekSummaryView: View {
    let items: [GameweekSummaryItem]
    let startIndex: Int
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0

    private let dismissThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            // Dimmed background — tap to dismiss
            Color.black.opacity(appeared ? 0.7 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: Theme.Spacing.s40) {
                Spacer()
                carousel
                pageIndicator
                Spacer()
            }
            .offset(y: dragOffset)
            .gesture(swipeToDismiss)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1 : 0)
        }
        .background(.clear)
        .onAppear {
            currentIndex = startIndex
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.8)
            ) {
                appeared = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Carousel

extension GameweekSummaryView {
    @ViewBuilder
    private var carousel: some View {
        if #available(iOS 17, *) {
            iOS17Carousel
        } else {
            legacyCarousel
        }
    }

    @available(iOS 17, *)
    private var iOS17Carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Theme.Spacing.s30) {
                ForEach(
                    Array(items.enumerated()),
                    id: \.element.id
                ) { _, item in
                    summaryCard(item)
                        .containerRelativeFrame(
                            .horizontal,
                            count: 1,
                            spacing: Theme.Spacing.s30
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(
            id: Binding(
                get: { items[safe: currentIndex]?.id },
                set: { newId in
                    if let newId,
                       let idx = items.firstIndex(
                           where: { $0.id == newId }
                       ) {
                        currentIndex = idx
                    }
                }
            )
        )
        .contentMargins(.horizontal, Theme.Spacing.s40)
    }

    /// Fallback tab-style carousel for iOS 16.
    private var legacyCarousel: some View {
        TabView(selection: $currentIndex) {
            ForEach(
                Array(items.enumerated()),
                id: \.element.id
            ) { index, item in
                summaryCard(item)
                    .padding(.horizontal, Theme.Spacing.s40)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 480)
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if items.count > 1 {
            HStack(spacing: Theme.Spacing.s10) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(
                            index == currentIndex
                                ? Theme.Color.Content.Text.default
                                : Theme.Color.Content.Text.disabled
                        )
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Summary Card

extension GameweekSummaryView {
    private func summaryCard(
        _ item: GameweekSummaryItem
    ) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            // League name
            Text(item.leagueName)
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )

            // Result icon
            Image(
                systemName: item.result == .survived
                    ? "checkmark.seal.fill"
                    : "xmark.seal.fill"
            )
            .font(.system(size: 60))
            .foregroundStyle(resultColor(item))
            .shadow(
                color: resultShadow(item),
                radius: 20
            )

            // Result title
            Text(
                item.result == .survived
                    ? "SURVIVED"
                    : "ELIMINATED"
            )
            .font(Theme.Typography.h2)
            .foregroundStyle(resultColor(item))

            // Score block
            scoreBlock(item)

            // Supporting pills
            HStack(spacing: Theme.Spacing.s20) {
                pill(
                    text: item.result == .survived
                        ? "Streak: \(item.survivalStreak)"
                        : "Streak ended",
                    color: resultColor(item)
                )
                pill(
                    text: "\(item.playersRemaining) of \(item.totalPlayers) left",
                    color: Theme.Color.Content.Text.subtle
                )
            }
        }
        .padding(.vertical, Theme.Spacing.s60)
        .padding(.horizontal, Theme.Spacing.s40)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r50)
        )
    }

    private func scoreBlock(
        _ item: GameweekSummaryItem
    ) -> some View {
        HStack(spacing: 0) {
            // Home side
            HStack(spacing: Theme.Spacing.s20) {
                TeamBadge(
                    teamName: item.homeTeamName,
                    logoURL: item.homeTeamLogo,
                    size: 32
                )
                Text(item.homeTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Score
            HStack(spacing: Theme.Spacing.s10) {
                if item.pickedHome {
                    pickDot(item)
                }
                Text("\(item.homeScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .monospacedDigit()
                Text("\u{2013}")
                    .font(Theme.Typography.h3)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                Text("\(item.awayScore)")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                    .monospacedDigit()
                if !item.pickedHome {
                    pickDot(item)
                }
            }

            // Away side
            HStack(spacing: Theme.Spacing.s20) {
                Spacer()
                Text(item.awayTeamShort)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                TeamBadge(
                    teamName: item.awayTeamName,
                    logoURL: item.awayTeamLogo,
                    size: 32
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func pickDot(
        _ item: GameweekSummaryItem
    ) -> some View {
        Image(
            systemName: item.result == .survived
                ? "checkmark.circle.fill"
                : "xmark.circle.fill"
        )
        .font(.system(size: 14))
        .foregroundStyle(resultColor(item))
    }

    private func pill(
        text: String,
        color: Color
    ) -> some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.vertical, Theme.Spacing.s10)
            .padding(.horizontal, Theme.Spacing.s20)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func resultColor(
        _ item: GameweekSummaryItem
    ) -> Color {
        item.result == .survived
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }

    private func resultShadow(
        _ item: GameweekSummaryItem
    ) -> Color {
        item.result == .survived
            ? .green.opacity(0.6)
            : .red.opacity(0.6)
    }
}

// MARK: - Swipe to Dismiss Gesture

extension GameweekSummaryView {
    private var swipeToDismiss: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
