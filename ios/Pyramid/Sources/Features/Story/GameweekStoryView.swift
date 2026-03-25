import SwiftUI

struct GameweekStoryView: View {
    @StateObject private var viewModel: GameweekStoryViewModel
    @Environment(\.dismiss)
    private var dismiss

    init(leagueId: String, gameweek: Int, leagueName: String, currentUserId: String?) {
        _viewModel = StateObject(wrappedValue: GameweekStoryViewModel(
            leagueId: leagueId,
            gameweek: gameweek,
            leagueName: leagueName,
            storyService: GameweekStoryService(),
            standingsService: StandingsService(),
            currentUserId: currentUserId
        ))
    }

    var body: some View {
        ZStack {
            Theme.Color.Surface.Background.page.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            } else {
                storyContent
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.load()
            await viewModel.markViewed()
        }
        .fullScreenCover(isPresented: $viewModel.showOverview) {
            GameweekOverviewView(viewModel: viewModel)
        }
    }

    private var storyContent: some View {
        ZStack {
            ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                StoryCardView(card: card)
                    .opacity(index == viewModel.currentIndex ? 1 : 0)
                    .scaleEffect(index == viewModel.currentIndex ? 1 : 0.97)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentIndex)
            }

            VStack {
                progressBars
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                Spacer()

                if viewModel.currentIndex == viewModel.totalCards - 1 {
                    Button {
                        viewModel.showOverview = true
                    } label: {
                        Text("View Full Recap")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Color.Primary.text)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Theme.Color.Primary.resting)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 48)
                }
            }

            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.goBack() }
                        .frame(width: geo.size.width * 0.3)

                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .onTapGesture { viewModel.advance() }
                }
            }
        }
    }

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.totalCards, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.currentIndex
                        ? Theme.color(light: "FFC758", dark: "FFC758")
                        : Color.white.opacity(0.15))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
            }
        }
        .accessibilityLabel("Card \(viewModel.currentIndex + 1) of \(viewModel.totalCards)")
    }
}
