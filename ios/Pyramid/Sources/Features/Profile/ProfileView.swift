import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.DS.Text.secondary)
                Text("Profile")
                    .font(.headline)
                    .foregroundStyle(Color.DS.Text.primary)
                Text("Your profile will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.DS.Text.secondary)

                NavigationLink(destination: NotificationPreferencesView()) {
                    Label("Notifications", systemImage: "bell")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.DS.Background.secondary)
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
