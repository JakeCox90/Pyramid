import os
import SwiftUI

@MainActor
final class CreateLeagueViewModel: ObservableObject {
    @Published var leagueName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var createdLeague: CreateLeagueResponse?

    private let leagueService: LeagueServiceProtocol

    var isNameValid: Bool {
        let trimmed = leagueName.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 3 && trimmed.count <= 40
    }

    var nameValidationMessage: String? {
        let trimmed = leagueName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count < 3 { return "Name must be at least 3 characters." }
        if trimmed.count > 40 { return "Name must be 40 characters or fewer." }
        return nil
    }

    init(leagueService: LeagueServiceProtocol = LeagueService()) {
        self.leagueService = leagueService
    }

    func submit() async {
        let name = leagueName.trimmingCharacters(in: .whitespaces)
        guard name.count >= 3 else {
            errorMessage = "League name must be at least 3 characters."
            return
        }
        guard name.count <= 40 else {
            errorMessage = "League name must be 40 characters or fewer."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            createdLeague = try await leagueService.createLeague(name: name)
        } catch {
            let message = error.localizedDescription
            Log.leagues.error("Create league failed: \(error.localizedDescription)")
            errorMessage = message.isEmpty
                ? "Failed to create league. Please try again."
                : message
            showErrorAlert = true
        }

        isLoading = false
    }
}
