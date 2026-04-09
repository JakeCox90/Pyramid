import SwiftUI

struct GameweekStoryView: View {
    @StateObject private var viewModel: GameweekStoryViewModel
    @Environment(\.dismiss)
    private var dismiss
    @State private var dragOffset: CGFloat = 0

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

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Color.Content.Text.contrast)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Theme.Color.Surface.Background.highlight)
                )
        }
        .accessibilityLabel("Close recap")
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
                HStack(alignment: .top) {
                    progressBars
                    closeButton
                }
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
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 120 {
                        dismiss()
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.totalCards, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.currentIndex
                        ? Theme.Color.Primary.resting
                        : Theme.Color.Border.default)
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
            }
        }
        .accessibilityLabel("Card \(viewModel.currentIndex + 1) of \(viewModel.totalCards)")
    }
}
