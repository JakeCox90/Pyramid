import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Profile")
                    .font(.headline)
                Text("Your profile will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
        }
    }
}
