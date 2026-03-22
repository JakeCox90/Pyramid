import SwiftUI

// Figma: Pick Carousel (node 32:4449)
// Horizontal paged carousel with swipe-up H2H reveal
// layout_HJCJZA: padding 0px 24px, gap 16px
// style_BJKFP1: "Pick a team" Inter Bold 44
// style_0BASS4: "GAMEWEEK 20" Inter Bold 12 uppercase

struct PickCarouselView: View {
    @ObservedObject var viewModel: PicksViewModel
    @State var currentIndex: Int = 0
    @State var cardOffsetY: CGFloat = 0
    @State var isStatsRevealed = false
    @State var dragOffsetX: CGFloat = 0

    // Figma: main card 352w, adjacent ~304w → 0.86 scale
    private let cardWidth: CGFloat = 352
    private let cardSpacing: CGFloat = 16
    private let peekScale: CGFloat = 0.86

    var body: some View {
        VStack(spacing: 16) {
            carouselHeader
                .padding(.horizontal, 24)
            carouselArea
        }
    }
}

// MARK: - Header

extension PickCarouselView {
    // Figma: Overline (Inter Bold 12 UPPER, white 40%)
    //        H1 (Inter Bold 44, white)
    private var carouselHeader: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let gameweek = viewModel.gameweek {
                Text(
                    "GAMEWEEK \(gameweek.roundNumber)"
                )
                .font(Theme.Typography.overline)
                .textCase(.uppercase)
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )
            }

            Text("Pick a team")
                .font(Theme.Typography.h1)
                .foregroundStyle(Color.white)

            if !viewModel.usedTeamIds.isEmpty {
                TeamsUsedPill(
                    teamNames: viewModel.usedTeamNames,
                    count: viewModel.usedTeamIds.count
                )
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Carousel Area

extension PickCarouselView {
    /// Step size: card width + spacing between cards
    private var stepSize: CGFloat {
        cardWidth + cardSpacing
    }

    /// Horizontal offset for the entire card strip
    private var stripOffset: CGFloat {
        -CGFloat(currentIndex) * stepSize + dragOffsetX
    }

    var carouselArea: some View {
        GeometryReader { geo in
            let midX = geo.size.width / 2
            HStack(spacing: cardSpacing) {
                ForEach(
                    Array(
                        viewModel.fixtures.enumerated()
                    ),
                    id: \.element.id
                ) { index, fixture in
                    let distance = abs(
                        stripOffset
                            + CGFloat(index) * stepSize
                            + cardWidth / 2
                            - midX
                    )
                    let progress = min(
                        distance / stepSize, 1
                    )
                    let scale = 1 - (1 - peekScale) * progress
                    carouselPage(
                        fixture: fixture,
                        index: index,
                        cardWidth: cardWidth
                    )
                    .frame(width: cardWidth)
                    .scaleEffect(scale)
                    .opacity(
                        index == currentIndex ? 1 : 0.7
                    )
                    .zIndex(
                        index == currentIndex ? 1 : 0
                    )
                }
            }
            .offset(
                x: stripOffset
                    + midX
                    - cardWidth / 2
            )
            .gesture(horizontalDrag)
            .animation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.85
                ),
                value: currentIndex
            )
            .animation(
                .interactiveSpring(),
                value: dragOffsetX
            )
        }
        .frame(height: 530)
    }

    private var horizontalDrag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                // Only handle horizontal drags
                // (vertical is for stats reveal)
                guard abs(dx) > abs(dy) else { return }
                // Rubber-band at edges
                let atStart = currentIndex == 0 && dx > 0
                let atEnd = currentIndex == viewModel.fixtures.count - 1 && dx < 0
                if atStart || atEnd {
                    dragOffsetX = dx * 0.3
                } else {
                    dragOffsetX = dx
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let velocity = value.predictedEndTranslation
                    .width
                let threshold = cardWidth * 0.3
                var newIndex = currentIndex
                if dx < -threshold || velocity < -cardWidth {
                    newIndex = min(currentIndex + 1, viewModel.fixtures.count - 1)
                } else if dx > threshold || velocity > cardWidth {
                    newIndex = max(currentIndex - 1, 0)
                }
                dragOffsetX = 0
                if newIndex != currentIndex {
                    currentIndex = newIndex
                    isStatsRevealed = false
                    cardOffsetY = 0
                }
            }
    }
}
