import XCTest
@testable import Pyramid

@MainActor
final class EditLeagueViewModelTests: XCTestCase {

    private func makeLeague(
        name: String = "Test League",
        description: String? = nil,
        emoji: String = "⚽",
        colorPalette: String = "primary"
    ) -> League {
        League(
            id: "league-1",
            name: name,
            joinCode: "ABC123",
            type: .free,
            status: .active,
            season: 2025,
            createdAt: Date(),
            createdBy: "user-1",
            colorPalette: colorPalette,
            emoji: emoji,
            description: description
        )
    }

    // MARK: - Initialization

    func testInitPopulatesFromLeague() {
        let league = makeLeague(
            name: "My League",
            description: "Cool league",
            emoji: "🔥",
            colorPalette: "primary"
        )
        let vm = EditLeagueViewModel(
            league: league,
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )

        XCTAssertEqual(vm.name, "My League")
        XCTAssertEqual(vm.description, "Cool league")
        XCTAssertEqual(vm.emoji, "🔥")
        XCTAssertEqual(vm.colorPalette, "primary")
    }

    func testInitWithNilDescription() {
        let league = makeLeague(description: nil)
        let vm = EditLeagueViewModel(
            league: league,
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )

        XCTAssertEqual(vm.description, "")
    }

    // MARK: - Validation

    func testNameTooShortIsInvalid() {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        vm.name = "AB"
        XCTAssertFalse(vm.isNameValid)
        XCTAssertNotNil(vm.nameValidationMessage)
    }

    func testNameTooLongIsInvalid() {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        vm.name = String(repeating: "A", count: 41)
        XCTAssertFalse(vm.isNameValid)
    }

    func testValidNameIsValid() {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        vm.name = "Good Name"
        XCTAssertTrue(vm.isNameValid)
        XCTAssertNil(vm.nameValidationMessage)
    }

    func testDescriptionTooLongIsInvalid() {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        vm.description = String(repeating: "A", count: 81)
        XCTAssertFalse(vm.isDescriptionValid)
        XCTAssertNotNil(vm.descriptionValidationMessage)
    }

    // MARK: - Has Changes

    func testNoChangesDetected() {
        let league = makeLeague(name: "Test League")
        let vm = EditLeagueViewModel(
            league: league,
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        XCTAssertFalse(vm.hasChanges)
    }

    func testNameChangeDetected() {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        vm.name = "New Name"
        XCTAssertTrue(vm.hasChanges)
    }

    func testEmojiChangeDetected() {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )
        vm.emoji = "🔥"
        XCTAssertTrue(vm.hasChanges)
    }

    // MARK: - Save

    func testSaveCallsServiceOnSuccess() async {
        let mock = MockLeagueService()
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: mock,
            moderationService: MockModerationService()
        )
        vm.name = "Updated Name"

        await vm.save()

        XCTAssertTrue(vm.didSave)
        XCTAssertNil(vm.errorMessage)
    }

    func testSaveFailsOnModerationReject() async {
        let mod = MockModerationService(isValid: false)
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: mod
        )
        vm.name = "Bad Name"

        await vm.save()

        XCTAssertFalse(vm.didSave)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.showErrorAlert)
    }

    func testSaveFailsOnServiceError() async {
        let mock = MockLeagueService(shouldFail: true)
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: mock,
            moderationService: MockModerationService()
        )
        vm.name = "Updated Name"

        await vm.save()

        XCTAssertFalse(vm.didSave)
        XCTAssertTrue(vm.showErrorAlert)
    }

    func testSaveDoesNothingWhenNoChanges() async {
        let vm = EditLeagueViewModel(
            league: makeLeague(),
            leagueService: MockLeagueService(),
            moderationService: MockModerationService()
        )

        await vm.save()

        XCTAssertFalse(vm.didSave)
    }
}

// MARK: - Mock Moderation Service

final class MockModerationService:
    ContentModerationServiceProtocol {

    let isValid: Bool
    let reason: String?

    init(
        isValid: Bool = true,
        reason: String? = "Content not allowed"
    ) {
        self.isValid = isValid
        self.reason = isValid ? nil : reason
    }

    func validate(
        name: String?,
        description: String?
    ) async throws -> ModerationResult {
        ModerationResult(
            valid: isValid,
            field: isValid ? nil : "name",
            reason: reason
        )
    }
}
