import SwiftUI

// Figma: Pick Carousel (node 32:4449)
// Horizontal paged carousel with flip-to-stats reveal
// layout_HJCJZA: padding 0px 24px, gap 16px
// style_BJKFP1: "Pick a team" Inter Bold 44
// style_0BASS4: "GAMEWEEK 20" Inter Bold 12 uppercase

struct PickCarouselView: View {
    @ObservedObject var viewModel: PicksViewModel
    @State var currentIndex: Int = 0
    @State var isStatsRevealed = false
    @State var dragOffsetX: CGFloat = 0

    private let cardSpacing: CGFloat = 16
    private let peekScale: CGFloat = 0.9
    /// Horizontal inset on each side for adjacent card peek
    private let peekInset: CGFloat = 24

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                carouselHeader
                    .padding(.horizontal, 24)
                teamsLeftPill
                    .padding(.horizontal, 24)
                    .padding(.bottom, -12)
                carouselArea
                paginationDots
                carouselBanners
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
        .scrollDisabled(true)
    }
}

// MARK: - Banners

extension PickCarouselView {
    @ViewBuilder var carouselBanners: some View {
        if let success = viewModel.successMessage {
            HStack {
                Image(systemName: Theme.Icon.Status.success)
                    .foregroundStyle(
                        Theme.Color.Status.Success.resting
                    )
                Text(success)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Spacer()
            }
            .padding(Theme.Spacing.s30)
            .background(Theme.Color.Status.Success.subtle)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
            .transition(
                .move(edge: .top)
                    .combined(with: .opacity)
            )
        }
        if let error = viewModel.errorMessage {
            HStack {
                Image(
                    systemName: Theme.Icon.Status.errorFill
                )
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )
                Text(error)
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                Spacer()
            }
            .padding(Theme.Spacing.s30)
            .background(Theme.Color.Status.Error.subtle)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r30
                )
            )
        }
    }
}

// MARK: - Pagination Dots

extension PickCarouselView {
    /// Figma: layout_AXZRY4 — padding 24px 0px, gap 10px
    var paginationDots: some View {
        HStack(spacing: 10) {
            ForEach(
                0..<viewModel.fixtures.count,
                id: \.self
            ) { index in
                Circle()
                    .fill(
                        index == currentIndex
                            ? Color.white
                            : Color.white.opacity(0.3)
                    )
                    .frame(width: 8, height: 8)
                    .animation(
                        .easeInOut(duration: 0.2),
                        value: currentIndex
                    )
            }
        }
        .padding(.top, 0)
        .padding(.bottom, 24)
    }
}

// MARK: - Header

extension PickCarouselView {
    /// Figma: layout_SLC3BU — padding 24px 24px 0px,
    /// gap 1px. Overline, H1, Label02 subtitle.
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

            Text(
                "Select a winning team from this week's fixtures"
            )
            .font(Theme.Typography.label02)
            .foregroundStyle(
                Color.white.opacity(0.4)
            )

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
            .simultaneousGesture(unifiedDrag(cardWidth: cw))
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
        .frame(height: 440)
    }

}
