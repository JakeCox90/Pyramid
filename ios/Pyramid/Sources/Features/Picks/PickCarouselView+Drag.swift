import SwiftUI

// MARK: - Drag Gesture Handling

extension PickCarouselView {
    /// Horizontal drag gesture for swiping between cards
    func unifiedDrag(
        cardWidth cw: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                handleHorizontalDrag(
                    dx: value.translation.width
                )
            }
            .onEnded { value in
                endHorizontalDrag(
                    dx: value.translation.width,
                    velocityX: value
                        .predictedEndTranslation.width,
                    cardWidth: cw
                )
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
        }
    }
}
