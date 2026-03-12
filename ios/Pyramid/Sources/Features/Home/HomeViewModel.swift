import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var homeData: HomeData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let homeService: HomeServiceProtocol

    init(homeService: HomeServiceProtocol = HomeService()) {
        self.homeService = homeService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            homeData = try await homeService.fetchHomeData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
