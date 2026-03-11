import SwiftUI

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Pick a Team Each Week",
            subtitle: "Choose one Premier League team per gameweek. "
                + "If they win or draw, you survive to the next round.",
            icon: "sportscourt",
            iconColor: Theme.Color.Primary.resting
        ),
        OnboardingPage(
            title: "Survive or Get Eliminated",
            subtitle: "Your team wins or draws — you're safe. "
                + "They lose — you're out. No second chances.",
            icon: "shield.checkered",
            iconColor: Theme.Color.Status.Success.resting
        ),
        OnboardingPage(
            title: "Last One Standing Wins",
            subtitle: "Outlast every other player in your league. "
                + "The last survivor takes it all.",
            icon: "trophy.fill",
            iconColor: Theme.Color.Status.Warning.resting
        )
    ]
}
