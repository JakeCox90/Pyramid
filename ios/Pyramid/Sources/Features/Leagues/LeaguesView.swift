import SwiftUI

struct LeaguesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "trophy")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No leagues yet")
                    .font(.headline)
                Text("Create or join a league to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Leagues")
        }
    }
}
