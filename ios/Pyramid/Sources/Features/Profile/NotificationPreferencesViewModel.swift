import Foundation

@MainActor
final class NotificationPreferencesViewModel: ObservableObject {
    @Published var preferences: NotificationPreferences = .defaultPreferences
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: NotificationPreferencesServiceProtocol
    private var saveTask: Task<Void, Never>?

    init(service: NotificationPreferencesServiceProtocol = NotificationPreferencesService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            preferences = try await service.fetchPreferences()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func save() async {
        saveTask?.cancel()
        saveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                guard !Task.isCancelled else { return }
                try await service.updatePreferences(preferences)
            } catch is CancellationError {
                // debounce cancelled — a newer save will run
            } catch {
                errorMessage = AppError.from(error).userMessage
            }
        }
        await saveTask?.value
    }
}
