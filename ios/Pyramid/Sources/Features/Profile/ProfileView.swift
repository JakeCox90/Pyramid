import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: SFSymbol.profileTab)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Profile")
                    .font(.headline)
                Text("Your profile will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                NavigationLink(destination: NotificationPreferencesView()) {
                    Label("Notifications", systemImage: SFSymbol.notifications)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
        }
    }
}
