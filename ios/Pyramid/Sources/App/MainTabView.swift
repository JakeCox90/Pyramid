import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: Int {
        case home
        case leagues
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: Theme.Icon.Navigation.home)
                }
                .tag(Tab.home)
                .accessibilityIdentifier(AccessibilityID.Tab.home)

            LeaguesView()
                .tabItem {
                    Label("Leagues", systemImage: Theme.Icon.Navigation.leagues)
                }
                .tag(Tab.leagues)
                .accessibilityIdentifier(AccessibilityID.Tab.leagues)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: Theme.Icon.Navigation.profile)
                }
                .tag(Tab.profile)
                .accessibilityIdentifier(AccessibilityID.Tab.profile)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToScreen)) { notification in
            guard let screen = notification.object as? String else { return }
            switch DeepLinkScreen(rawValue: screen) {
            case .picks, .standings:
                selectedTab = .leagues
            case .wallet:
                if FeatureFlags.paidFeaturesEnabled {
                    selectedTab = .profile
                }
            case .none:
                selectedTab = .profile
            }
        }
    }
}
