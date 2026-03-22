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
    // style_0BASS4: Inter Bold 12, uppercase, left,
    // white 40%
    // style_BJKFP1: Inter Bold 44, left, white
    private var carouselHeader: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let gameweek = viewModel.gameweek {
                Text(
                    "GAMEWEEK \(gameweek.roundNumber)"
                )
                .font(
                    Font.custom("Inter-Bold", size: 12)
                )
                .textCase(.uppercase)
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )
            }

            Text("Pick a team")
                .font(
                    .custom("Inter-Bold", size: 44)
                )
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
    var carouselArea: some View {
        TabView(selection: $currentIndex) {
            ForEach(
                Array(
                    viewModel.fixtures.enumerated()
                ),
                id: \.element.id
            ) { index, fixture in
                carouselPage(
                    fixture: fixture,
                    index: index,
                    cardWidth: 352
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .disabled(isStatsRevealed)
    }
}
