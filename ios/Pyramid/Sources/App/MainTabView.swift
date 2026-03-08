import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .leagues

    enum Tab: Int {
        case leagues
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LeaguesView()
                .tabItem {
                    Label("Leagues", systemImage: "trophy")
                }
                .tag(Tab.leagues)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(Tab.profile)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToScreen)) { notification in
            guard let screen = notification.object as? String else { return }
            switch DeepLinkScreen(rawValue: screen) {
            case .picks, .standings:
                selectedTab = .leagues
            case .wallet, .none:
                selectedTab = .profile
            }
        }
    }
}
