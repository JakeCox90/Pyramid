#if DEBUG
import SwiftUI

enum ComponentTab: String, CaseIterable {
    case avatar = "Avatar"
    case button = "Button"
    case card = "Card"
    case confetti = "Confetti"
    case detailSheet = "Detail Sheet"
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
    case outcomeCard = "Outcome"
    case tabs = "Tabs"
    case teamBadge = "Team Badge"
    case teamsUsed = "Teams Used"
    case toast = "Toast"
}

struct ComponentBrowserView: View {
    @State private var selectedTab: ComponentTab =
        .button

    var body: some View {
        VStack(spacing: 0) {
            Tabs(selected: $selectedTab)
            tabContent
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
        case .outcomeCard: OutcomeCardDemo()
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
        case .tabs: TabsDemo()
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
