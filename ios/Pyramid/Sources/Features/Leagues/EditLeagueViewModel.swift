import SwiftUI

@MainActor
final class EditLeagueViewModel: ObservableObject {
    @Published var name: String
    @Published var description: String
    @Published var emoji: String
    @Published var colorPalette: String
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var didSave = false

    let league: League
    private let leagueService: LeagueServiceProtocol
    private let moderationService:
        ContentModerationServiceProtocol

    var isNameValid: Bool {
        let trimmed = name.trimmingCharacters(
            in: .whitespaces
        )
        return trimmed.count >= 3 && trimmed.count <= 40
    }

    var nameValidationMessage: String? {
        let trimmed = name.trimmingCharacters(
            in: .whitespaces
        )
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count < 3 {
            return "Name must be at least 3 characters."
        }
        if trimmed.count > 40 {
            return "Name must be 40 characters or fewer."
        }
        return nil
    }

    var isDescriptionValid: Bool {
        description.count <= 80
    }

    var descriptionValidationMessage: String? {
        guard !description.isEmpty else { return nil }
        if description.count > 80 {
            return "Description must be 80 characters or fewer."
        }
        return nil
    }

    var hasChanges: Bool {
        name != league.name
            || description != (league.description ?? "")
            || emoji != league.emoji
            || colorPalette != league.colorPalette
    }

    var canSave: Bool {
        isNameValid && isDescriptionValid && hasChanges
            && !isLoading
    }

    init(
        league: League,
        leagueService: LeagueServiceProtocol =
            LeagueService(),
        moderationService: ContentModerationServiceProtocol =
            ContentModerationService()
    ) {
        self.league = league
        self.leagueService = leagueService
        self.moderationService = moderationService
        self.name = league.name
        self.description = league.description ?? ""
        self.emoji = league.emoji
        self.colorPalette = league.colorPalette
    }

    func save() async {
        guard canSave else { return }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await moderationService
                .validate(
                    name: name,
                    description: description.isEmpty
                        ? nil : description
                )
            if !result.valid {
                errorMessage = result.reason
                    ?? "Content not allowed."
                showErrorAlert = true
                isLoading = false
                return
            }

            try await leagueService.updateLeague(
                leagueId: league.id,
                name: name.trimmingCharacters(
                    in: .whitespaces
                ),
                description: description.isEmpty
                    ? nil : description,
                colorPalette: colorPalette,
                emoji: emoji
            )
            didSave = true
        } catch {
            errorMessage = AppError.from(error).userMessage
            showErrorAlert = true
        }

        isLoading = false
    }
}
