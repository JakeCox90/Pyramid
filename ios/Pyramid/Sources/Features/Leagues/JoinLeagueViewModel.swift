import SwiftUI

enum JoinLeagueStep {
    case enterCode
    case preview(LeaguePreview)
    case joined(JoinLeagueResponse)
}

@MainActor
final class JoinLeagueViewModel: ObservableObject {
    @Published var code = ""
    @Published var step: JoinLeagueStep = .enterCode
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let leagueService: LeagueServiceProtocol

    var normalizedCode: String {
        code.trimmingCharacters(in: .whitespaces).uppercased()
    }

    var isCodeValid: Bool {
        normalizedCode.count == 6
    }

    init(leagueService: LeagueServiceProtocol = LeagueService()) {
        self.leagueService = leagueService
    }

    func lookupCode() async {
        guard isCodeValid else {
            errorMessage = "Enter a 6-character join code."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let preview = try await leagueService.previewLeague(code: normalizedCode)
            step = .preview(preview)
        } catch {
            errorMessage = AppError.from(error).userMessage
        }

        isLoading = false
    }

    func confirmJoin() async {
        guard case .preview = step else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await leagueService.joinLeague(code: normalizedCode)
            step = .joined(response)
        } catch {
            errorMessage = AppError.from(error).userMessage
        }

        isLoading = false
    }

    func resetToEnterCode() {
        step = .enterCode
        errorMessage = nil
    }
}
