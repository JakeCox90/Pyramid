import SwiftUI

// MARK: - Dark theme colour constants (shared with JoinPaidLeagueView)

private let bgCard = Color(hex: "1C1C1E")
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.6)
private let brandBlue = Color(hex: "1A56DB")
private let errorRed = Color(hex: "FF453A")

// MARK: - JoinPaidLeagueView helper subviews

extension JoinPaidLeagueView {
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.DS.subheadline)
                .foregroundStyle(textSecondary)
            Spacer()
            Text(value)
                .font(.DS.subheadline)
                .foregroundStyle(textPrimary)
        }
    }

    func ruleItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: icon)
                .font(.DS.caption1)
                .foregroundStyle(brandBlue)
                .frame(width: 16)
            Text(text)
                .font(.DS.caption1)
                .foregroundStyle(textSecondary)
        }
    }

    func errorBanner(message: String) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(errorRed)
            Text(message)
                .font(.DS.caption1)
                .foregroundStyle(textPrimary)
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(errorRed.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    func infoChip(label: String, value: String) -> some View {
        VStack(spacing: DS.Spacing.s1) {
            Text(label)
                .font(.DS.caption1)
                .foregroundStyle(textSecondary)
            Text(value)
                .font(.DS.headline)
                .foregroundStyle(textPrimary)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}

// MARK: - Pulse animation modifier

struct PulsingModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 0.85 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

extension View {
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
}
