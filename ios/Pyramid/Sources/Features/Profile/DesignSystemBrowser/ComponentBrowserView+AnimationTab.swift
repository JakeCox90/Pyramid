#if DEBUG
import SwiftUI

struct ConfettiDemo: View {
    var body: some View {
        DemoPageStatic {
            ConfettiView()
                .frame(height: 160)
        }
    }
}
#endif
