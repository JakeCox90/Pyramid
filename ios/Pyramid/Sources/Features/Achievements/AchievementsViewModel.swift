import Foundation
import SwiftUI

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var displayBadges: [DisplayBadge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: AchievementServiceProtocol
    private let cacheKey = "unlocked_achievement_ids"

    struct DisplayBadge: Identifiable {
        let definition: BadgeDefinition
        let unlocked: Achievement?
        var isUnlocked: Bool { unlocked != nil }
        var id: String { definition.id }
    }

    init(
        service: AchievementServiceProtocol = AchievementService()
    ) {
        self.service = service
    }

    func loadAchievements() async {
        isLoading = true
        errorMessage = nil
        do {
            let unlocked = try await service.fetchUnlocked()
            let unlockedMap = Dictionary(
                uniqueKeysWithValues: unlocked.map {
                    ($0.achievementId, $0)
                }
            )

            displayBadges = AchievementCatalog.allBadges.map {
                DisplayBadge(
                    definition: $0,
                    unlocked: unlockedMap[$0.id]
                )
            }
        } catch {
            let message = error.localizedDescription
            if message.contains("schema cache") ||
                message.contains("relation") ||
                message.contains("does not exist") {
                // Table not yet available — show empty
                displayBadges =
                    AchievementCatalog.allBadges.map {
                        DisplayBadge(
                            definition: $0,
                            unlocked: nil
                        )
                    }
            } else {
                errorMessage = message
            }
        }
        isLoading = false
    }

    func checkForNewBadges(
        toastManager: ToastManager
    ) async {
        do {
            let unlocked = try await service.fetchUnlocked()
            let currentIds = Set(
                unlocked.map { $0.achievementId }
            )
            let cachedIds = Set(
                UserDefaults.standard.stringArray(
                    forKey: cacheKey
                ) ?? []
            )
            let newIds = currentIds.subtracting(cachedIds)

            for newId in newIds {
                if let badge = AchievementCatalog.badge(
                    for: newId
                ) {
                    toastManager.show(
                        icon: badge.icon,
                        title: badge.name,
                        subtitle: badge.description,
                        style: badge.style
                    )
                }
            }

            UserDefaults.standard.set(
                Array(currentIds),
                forKey: cacheKey
            )
        } catch {
            // Non-critical — silently fail
        }
    }
}
