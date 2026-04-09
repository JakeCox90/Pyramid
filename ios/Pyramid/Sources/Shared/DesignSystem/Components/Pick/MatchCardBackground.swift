import SwiftUI

// Shared purple gradient background used by MatchCarouselCard and FixturePickRow.
// fill_255PQ5 / fill_CRMJ7P: linear-gradient(225deg, rgba(94,78,129,1) 0%,
//              rgba(45,37,61,1) 72%) over #241E31
struct MatchCardBackground: View {
    var body: some View {
        ZStack {
            Theme.Color.Surface.Background.page
            LinearGradient(
                stops: [
                    .init(
                        color: Theme.Color.Match.Gradient.purpleStart,
                        location: 0.0
                    ),
                    .init(
                        color: Theme.Color.Match.Gradient.purpleEnd,
                        location: 0.72
                    )
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}
