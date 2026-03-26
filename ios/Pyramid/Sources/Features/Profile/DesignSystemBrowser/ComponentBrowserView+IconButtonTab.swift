#if DEBUG
import SwiftUI

struct IconButtonDemo: View {
    @State private var variant: ButtonVariant = .primary
    @State private var selectedIcon = "plus"

    private let iconOptions = [
        ("plus", Theme.Icon.Navigation.add),
        ("share", Theme.Icon.Action.share),
        ("error", Theme.Icon.Status.failure),
        ("bell", Theme.Icon.Navigation.notifications)
    ]

    var body: some View {
        DemoPage {
            IconButton(
                icon: iconOptions.first {
                    $0.0 == selectedIcon
                }?.1 ?? Theme.Icon.Navigation.add,
                variant: variant
            ) {}
        } config: {
            ConfigRow(label: "Variant") {
                Picker("", selection: $variant) {
                    Text("primary")
                        .tag(ButtonVariant.primary)
                    Text("secondary")
                        .tag(ButtonVariant.secondary)
                    Text("destructive")
                        .tag(
                            ButtonVariant.destructive
                        )
                    Text("ghost")
                        .tag(ButtonVariant.ghost)
                }
            }
            ConfigDivider()
            ConfigRow(label: "Icon") {
                Picker(
                    "", selection: $selectedIcon
                ) {
                    Text("plus").tag("plus")
                    Text("share").tag("share")
                    Text("error").tag("error")
                    Text("bell").tag("bell")
                }
            }
        }
    }
}
#endif
