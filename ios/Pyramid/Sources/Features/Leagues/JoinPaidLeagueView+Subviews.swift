import SwiftUI

// MARK: - Dark theme colour constants (shared across JoinPaidLeagueView files)

enum JoinPaidLeagueColors {
    static let bgPrimary = Color(hex: "0A0A0A")
    static let bgCard = Color(hex: "1C1C1E")
    static let bgElevated = Color(hex: "2C2C2E")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let brandBlue = Color(hex: "1A56DB")
    static let successGreen = Color(hex: "30D158")
    static let errorRed = Color(hex: "FF453A")
    static let warningYellow = Color(hex: "FFD60A")
    static let separator = Color(hex: "38383A")
}

private typealias Colors = JoinPaidLeagueColors

// MARK: - JoinPaidLeagueView state views

extension JoinPaidLeagueView {

    // MARK: - State 2: Waiting

    func waitingStateView(
        result: JoinPaidLeagueResponse
    ) -> some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Colors.successGreen.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Colors.successGreen)
                    .pulsing()
            }

            VStack(spacing: DS.Spacing.s2) {
                Text("You're in!")
                    .font(.DS.title1)
                    .foregroundStyle(Colors.textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(.DS.subheadline)
                    .foregroundStyle(Colors.textSecondary)
            }

            playerCountCard(result: result)

            Text("Starts when 5 players join")
                .font(.DS.caption1)
                .foregroundStyle(Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") {
                onJoined?(result)
                dismiss()
            }
            .dsStyle(.primary)
            .padding(.bottom, DS.Spacing.s8)
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    func playerCountCard(
        result: JoinPaidLeagueResponse
    ) -> some View {
        let total = 5
        let current = min(result.playerCount, total)
        let progress = Double(current) / Double(total)

        return VStack(spacing: DS.Spacing.s3) {
            HStack {
                Text("\(current) / \(total) players joined")
                    .font(.DS.headline)
                    .foregroundStyle(Colors.textPrimary)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Colors.bgElevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Colors.brandBlue)
                        .frame(
                            width: geo.size.width * progress,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(DS.Spacing.s4)
        .background(Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    // MARK: - State 3: Active

    func activeStateView(
        result: JoinPaidLeagueResponse
    ) -> some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(Colors.warningYellow)

            VStack(spacing: DS.Spacing.s2) {
                Text("Round started!")
                    .font(.DS.title1)
                    .foregroundStyle(Colors.textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(.DS.subheadline)
                    .foregroundStyle(Colors.textSecondary)
            }

            infoChip(
                label: "League ID",
                value: result.leagueId
            )

            Spacer()

            VStack(spacing: DS.Spacing.s3) {
                Button("View League") {
                    onJoined?(result)
                    dismiss()
                }
                .dsStyle(.primary)

                Button("Done") {
                    dismiss()
                }
                .dsStyle(.ghost)
            }
            .padding(.bottom, DS.Spacing.s8)
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }
}

// MARK: - JoinPaidLeagueView helper subviews

extension JoinPaidLeagueView {
    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.DS.subheadline)
                .foregroundStyle(Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.DS.subheadline)
                .foregroundStyle(Colors.textPrimary)
        }
    }

    func ruleItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: icon)
                .font(.DS.caption1)
                .foregroundStyle(Colors.brandBlue)
                .frame(width: 16)
            Text(text)
                .font(.DS.caption1)
                .foregroundStyle(Colors.textSecondary)
        }
    }

    func errorBanner(message: String) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Colors.errorRed)
            Text(message)
                .font(.DS.caption1)
                .foregroundStyle(Colors.textPrimary)
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(Colors.errorRed.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    func infoChip(label: String, value: String) -> some View {
        VStack(spacing: DS.Spacing.s1) {
            Text(label)
                .font(.DS.caption1)
                .foregroundStyle(Colors.textSecondary)
            Text(value)
                .font(.DS.headline)
                .foregroundStyle(Colors.textPrimary)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background(Colors.bgCard)
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
