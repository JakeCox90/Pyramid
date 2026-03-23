#if DEBUG
import SwiftUI

struct DesignSystemBrowserView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Tokens").tag(0)
                Text("Components").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s20)

            if selectedTab == 0 {
                TokenBrowserView()
            } else {
                ComponentBrowserView()
            }
        }
        .background(
            Theme.Color.Surface.Background.page.ignoresSafeArea()
        )
        .navigationTitle("Design System")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DesignSystemBrowserView()
    }
}
#endif
