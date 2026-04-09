import SwiftUI

/// A horizontally-scrolling capsule-pill tab picker.
///
/// Usage:
/// ```swift
/// Tabs(selected: $selectedTab)
/// ```
///
/// The tab type must conform to `Hashable`, `CaseIterable`,
/// and `RawRepresentable<String>`. The raw value is used as
/// the display label.
struct Tabs<Tab>: View
where Tab: Hashable & CaseIterable & RawRepresentable,
      Tab.RawValue == String,
      Tab.AllCases: RandomAccessCollection {

    @Binding var selected: Tab

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: Theme.Spacing.s20) {
                    ForEach(
                        Tab.allCases,
                        id: \.self
                    ) { tab in
                        Button {
                            withAnimation(
                                .easeInOut(duration: 0.2)
                            ) {
                                selected = tab
                            }
                        } label: {
                            Text(tab.rawValue)
                                .font(Theme.Typography.label01)
                                .foregroundStyle(
                                    selected == tab
                                        ? Theme.Color.Content.Text.default
                                        : Theme.Color.Content.Text.subtle
                                )
                                .padding(
                                    .horizontal,
                                    Theme.Spacing.s30
                                )
                                .padding(
                                    .vertical,
                                    Theme.Spacing.s20
                                )
                                .background(
                                    selected == tab
                                        ? Theme.Color.Surface.Background.highlight
                                        : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .id(tab)
                    }
                }
                .padding(
                    .horizontal,
                    Theme.Spacing.s40
                )
                .padding(
                    .vertical,
                    Theme.Spacing.s20
                )
            }
            .onChange(of: selected) { newTab in
                withAnimation {
                    proxy.scrollTo(newTab, anchor: .center)
                }
            }
        }
    }
}
