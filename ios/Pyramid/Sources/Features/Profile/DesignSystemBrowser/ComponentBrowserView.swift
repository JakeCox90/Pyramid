#if DEBUG
import SwiftUI

enum ComponentTab: String, CaseIterable {
    case button = "Button"
    case card = "Card"
    case input = "Input"
    case flag = "Flag"
    case feedback = "Feedback"
    case animation = "Animation"
    case element = "Element"
}

struct ComponentBrowserView: View {
    @State private var selectedTab: ComponentTab = .button
    @State var sampleText = ""
    @State var sampleEmoji = "⚽"
    @State var samplePalette = "primary"

    var body: some View {
        VStack(spacing: 0) {
            tabPicker
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s60
                ) {
                    tabContent
                }
                .padding(Theme.Spacing.s40)
            }
        }
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s20) {
                ForEach(
                    ComponentTab.allCases,
                    id: \.self
                ) { tab in
                    Button(tab.rawValue) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                    .themed(
                        selectedTab == tab
                            ? .secondary : .ghost,
                        fullWidth: false
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s20)
        }
    }

    @ViewBuilder var tabContent: some View {
        switch selectedTab {
        case .button:
            buttonContent
        case .card:
            cardContent
        case .input:
            inputContent
        case .flag:
            flagContent
        case .feedback:
            feedbackContent
        case .animation:
            animationContent
        case .element:
            elementContent
        }
    }
}

#Preview {
    NavigationStack {
        ComponentBrowserView()
    }
}
#endif
