import SwiftUI

struct ToastConfiguration: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    let style: FlagVariant
    let duration: TimeInterval

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        style: FlagVariant = .success,
        duration: TimeInterval = 3.0
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.duration = duration
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
final class ToastManager: ObservableObject {
    @Published private(set) var current: ToastConfiguration?
    private var queue: [ToastConfiguration] = []
    private var dismissTask: Task<Void, Never>?

    func show(_ config: ToastConfiguration) {
        queue.append(config)
        if current == nil {
            showNext()
        }
    }

    func show(
        icon: String,
        title: String,
        subtitle: String? = nil,
        style: FlagVariant = .success
    ) {
        show(ToastConfiguration(
            icon: icon,
            title: title,
            subtitle: subtitle,
            style: style
        ))
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            current = nil
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            showNext()
        }
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        withAnimation(.spring(duration: 0.3)) {
            current = next
        }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(next.duration))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }
}
