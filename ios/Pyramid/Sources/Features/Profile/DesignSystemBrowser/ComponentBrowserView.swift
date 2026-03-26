#if DEBUG
import SwiftUI

enum ComponentTab: String, CaseIterable {
    case avatar = "Avatar"
    case button = "Button"
    case card = "Card"
    case confetti = "Confetti"
    case detailSheet = "Detail Sheet"
    case eliminationCard = "Elimination"
    case emojiPicker = "Emoji Picker"
    case emptyState = "Empty State"
    case flag = "Flag"
    case iconBadge = "Icon Badge"
    case iconButton = "Icon Button"
    case inputField = "Input Field"
    case leagueCard = "League Card"
    case matchCard = "Match Card"
    case matchStats = "Match Stats"
    case palettePicker = "Palette"
    case pickLarge = "Pick Large"
    case pickSmall = "Pick Small"
    case playersLeft = "Players Left"
    case pulsingDot = "Pulsing Dot"
    case resultCard = "Result Card"
    case survivalCard = "Survival"
    case teamBadge = "Team Badge"
    case teamsUsed = "Teams Used"
    case toast = "Toast"
}

struct ComponentBrowserView: View {
    @State private var selectedTab: ComponentTab =
        .button

    var body: some View {
        VStack(spacing: 0) {
            tabPicker
            tabContent
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: Theme.Spacing.s20) {
                    ForEach(
                        ComponentTab.allCases,
                        id: \.self
                    ) { tab in
                        Button {
                            withAnimation(
                                .easeInOut(
                                    duration: 0.2
                                )
                            ) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab.rawValue)
                                .font(
                                    Theme.Typography
                                        .label01
                                )
                                .foregroundStyle(
                                    selectedTab == tab
                                        ? Theme.Color
                                            .Content
                                            .Text
                                            .default
                                        : Theme.Color
                                            .Content
                                            .Text
                                            .subtle
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
                                    selectedTab == tab
                                        ? Theme.Color
                                            .Surface
                                            .Background
                                            .highlight
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
                    .vertical, Theme.Spacing.s20
                )
            }
            .onChange(
                of: selectedTab
            ) { newTab in
                withAnimation {
                    proxy.scrollTo(
                        newTab, anchor: .center
                    )
                }
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder var tabContent: some View {
        switch selectedTab {
        case .avatar: AvatarDemo()
        case .button: ButtonDemo()
        case .card: CardDemo()
        case .confetti: ConfettiDemo()
        case .detailSheet: DetailSheetDemo()
        case .eliminationCard: EliminationCardDemo()
        case .emojiPicker: EmojiPickerDemo()
        case .emptyState: EmptyStateDemo()
        case .flag: FlagDemo()
        case .iconBadge: IconBadgeDemo()
        case .iconButton: IconButtonDemo()
        case .inputField: InputFieldDemo()
        case .leagueCard: LeagueCardDemo()
        case .matchCard: MatchCardDemo()
        case .matchStats: MatchStatsDemo()
        case .palettePicker: PalettePickerDemo()
        case .pickLarge: PickLargeDemo()
        case .pickSmall: PickSmallDemo()
        case .playersLeft: PlayersRemainingDemo()
        case .pulsingDot: PulsingDotDemo()
        case .resultCard: ResultCardDemo()
        case .survivalCard: SurvivalCardDemo()
        case .teamBadge: TeamBadgeDemo()
        case .teamsUsed: TeamsUsedPillDemo()
        case .toast: ToastDemo()
        }
    }
}

#Preview {
    NavigationStack {
        ComponentBrowserView()
    }
}
#endif
