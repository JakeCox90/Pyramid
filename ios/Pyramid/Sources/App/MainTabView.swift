import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LeaguesView()
                .tabItem {
                    Label("Leagues", systemImage: "trophy")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}
