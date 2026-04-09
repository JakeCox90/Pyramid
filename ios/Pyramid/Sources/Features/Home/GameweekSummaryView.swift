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
            Theme.Color.Surface.Overlay.heavy.opacity(appeared ? 1 : 0)
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

    func dismiss() {
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
    @ViewBuilder private var carousel: some View {
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

    @ViewBuilder private var pageIndicator: some View {
        if items.count > 1 {
            HStack(spacing: Theme.Spacing.s10) {
                ForEach(
                    0..<items.count, id: \.self
                ) { index in
                    Circle()
                        .fill(
                            index == currentIndex
                                ? Theme.Color.Content.Text
                                    .default
                                : Theme.Color.Content.Text
                                    .disabled
                        )
                        .frame(width: 8, height: 8)
                }
            }
        }
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
