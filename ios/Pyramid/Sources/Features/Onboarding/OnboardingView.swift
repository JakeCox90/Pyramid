import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            skipButton
            carousel
            pageIndicator
            bottomSection
        }
        .background(
            Theme.Color.Surface.Background.page.ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Skip

    private var skipButton: some View {
        HStack {
            Spacer()
            if currentPage < OnboardingPage.allPages.count - 1 {
                Button("Skip") { completeOnboarding() }
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.top, Theme.Spacing.s20)
        .frame(height: 44)
    }

    // MARK: - Carousel

    private var carousel: some View {
        TabView(selection: $currentPage) {
            ForEach(
                Array(OnboardingPage.allPages.enumerated()),
                id: \.offset
            ) { index, page in
                pageView(page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 72))
                .foregroundStyle(page.iconColor)

            VStack(spacing: Theme.Spacing.s20) {
                Text(page.title)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: Theme.Spacing.s20) {
            ForEach(0..<OnboardingPage.allPages.count, id: \.self) { index in
                Circle()
                    .fill(
                        index == currentPage
                            ? Theme.Color.Content.Text.default
                            : Theme.Color.Border.default
                    )
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, Theme.Spacing.s40)
    }

    // MARK: - Bottom CTAs

    private var bottomSection: some View {
        VStack(spacing: Theme.Spacing.s30) {
            if currentPage == OnboardingPage.allPages.count - 1 {
                Button("Get Started") { completeOnboarding() }
                    .dsStyle(.primary)
            } else {
                Button("Next") {
                    withAnimation { currentPage += 1 }
                }
                .dsStyle(.primary)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.bottom, Theme.Spacing.s60)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        appState.completeOnboarding()
    }
}
