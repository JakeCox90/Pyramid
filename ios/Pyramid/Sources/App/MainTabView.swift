import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .leagues
    @State private var settlementLeagueId: String?
    @State private var settlementGameweekId: Int?
    @State private var showSettlement = false

    enum Tab: Int {
        case leagues
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LeaguesView()
                .tabItem {
                    Label("Leagues", systemImage: Theme.Icon.Navigation.leagues)
                }
                .tag(Tab.leagues)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: Theme.Icon.Navigation.profile)
                }
                .tag(Tab.profile)
        }
        .sheet(isPresented: $showSettlement) {
            if let leagueId = settlementLeagueId,
               let gameweekId = settlementGameweekId {
                SettlementResultView(
                    leagueId: leagueId,
                    gameweekId: gameweekId
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateWithPayload)) { notification in
            guard let payload = notification.object as? DeepLinkPayload else { return }
            handleDeepLinkPayload(payload)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToScreen)) { notification in
            guard let screen = notification.object as? String else { return }
            switch DeepLinkScreen(rawValue: screen) {
            case .picks, .standings, .settlement:
                selectedTab = .leagues
            case .wallet, .none:
                selectedTab = .profile
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLinkPayload(_ payload: DeepLinkPayload) {
        switch payload.screen {
        case .settlement:
            guard let leagueId = payload.leagueId,
                  let gameweekId = payload.gameweekId else {
                selectedTab = .leagues
                return
            }
            settlementLeagueId = leagueId
            settlementGameweekId = gameweekId
            selectedTab = .leagues
            showSettlement = true
        case .picks, .standings:
            selectedTab = .leagues
        case .wallet:
            selectedTab = .profile
        }
    }
}
