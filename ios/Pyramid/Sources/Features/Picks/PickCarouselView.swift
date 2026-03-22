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
    /// Tracks initial drag direction to lock gesture axis
    @State var dragAxis: DragAxis = .undecided

    enum DragAxis {
        case undecided, horizontal, vertical
    }

    private let cardSpacing: CGFloat = 8
    private let peekScale: CGFloat = 0.9
    /// Horizontal inset on each side for adjacent card peek
    private let peekInset: CGFloat = 24

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
    /// Card width based on screen, leaving room for peek
    func cardWidth(in screenWidth: CGFloat) -> CGFloat {
        screenWidth - peekInset * 2
    }

    /// Step size: card width + spacing between cards
    func stepSize(in screenWidth: CGFloat) -> CGFloat {
        cardWidth(in: screenWidth) + cardSpacing
    }

    /// Horizontal offset for the entire card strip
    func stripOffset(in screenWidth: CGFloat) -> CGFloat {
        let step = stepSize(in: screenWidth)
        return -CGFloat(currentIndex) * step + dragOffsetX
    }

    var carouselArea: some View {
        GeometryReader { geo in
            let sw = geo.size.width
            let cw = cardWidth(in: sw)
            let step = stepSize(in: sw)
            let offset = stripOffset(in: sw)
            let midX = sw / 2

            HStack(spacing: cardSpacing) {
                ForEach(
                    Array(
                        viewModel.fixtures.enumerated()
                    ),
                    id: \.element.id
                ) { index, fixture in
                    let dist = abs(
                        offset
                            + CGFloat(index) * step
                            + cw / 2
                            - midX
                    )
                    let progress = min(dist / step, 1)
                    let scale =
                        1 - (1 - peekScale) * progress
                    carouselPage(
                        fixture: fixture,
                        index: index,
                        cardWidth: cw
                    )
                    .frame(width: cw)
                    .scaleEffect(scale)
                    .opacity(
                        index == currentIndex ? 1 : 0.7
                    )
                    .zIndex(
                        index == currentIndex ? 1 : 0
                    )
                }
            }
            .offset(x: offset + midX - cw / 2)
            .contentShape(Rectangle())
            .gesture(unifiedDrag(cardWidth: cw))
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
            .animation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.8
                ),
                value: isStatsRevealed
            )
            .animation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.8
                ),
                value: cardOffsetY
            )
        }
        .frame(height: 520)
    }

    /// Single drag gesture handling both horizontal
    /// (swipe between cards) and vertical (stats reveal)
    private func unifiedDrag(
        cardWidth cw: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                // Lock axis on first significant movement
                if dragAxis == .undecided {
                    if abs(dx) > 8 || abs(dy) > 8 {
                        dragAxis = abs(dx) >= abs(dy)
                            ? .horizontal : .vertical
                    }
                }
                switch dragAxis {
                case .horizontal:
                    handleHorizontalDrag(dx: dx)
                case .vertical:
                    handleVerticalDrag(dy: dy)
                case .undecided:
                    break
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let vel = value.predictedEndTranslation
                switch dragAxis {
                case .horizontal:
                    endHorizontalDrag(
                        dx: dx,
                        velocityX: vel.width,
                        cardWidth: cw
                    )
                case .vertical:
                    endVerticalDrag(dy: dy)
                case .undecided:
                    break
                }
                dragAxis = .undecided
            }
    }

    private func handleHorizontalDrag(dx: CGFloat) {
        let count = viewModel.fixtures.count
        let atStart = currentIndex == 0 && dx > 0
        let atEnd =
            currentIndex == count - 1 && dx < 0
        dragOffsetX = (atStart || atEnd)
            ? dx * 0.3 : dx
    }

    private func endHorizontalDrag(
        dx: CGFloat,
        velocityX: CGFloat,
        cardWidth cw: CGFloat
    ) {
        let threshold = cw * 0.25
        let count = viewModel.fixtures.count
        var newIndex = currentIndex
        if dx < -threshold || velocityX < -cw {
            newIndex = min(currentIndex + 1, count - 1)
        } else if dx > threshold || velocityX > cw {
            newIndex = max(currentIndex - 1, 0)
        }
        dragOffsetX = 0
        if newIndex != currentIndex {
            currentIndex = newIndex
            isStatsRevealed = false
            cardOffsetY = 0
        }
    }

    private func handleVerticalDrag(dy: CGFloat) {
        if isStatsRevealed && dy > 0 {
            cardOffsetY = dy
        } else if !isStatsRevealed && dy < 0 {
            cardOffsetY = dy
        }
    }

    private func endVerticalDrag(dy: CGFloat) {
        if isStatsRevealed && dy > 80 {
            isStatsRevealed = false
        } else if !isStatsRevealed && dy < -100 {
            isStatsRevealed = true
        }
        cardOffsetY = 0
    }
}
