import SwiftUI

private typealias C = JoinPaidLeagueColors

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
                    .fill(C.successGreen.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(C.successGreen)
                    .pulsing()
            }

            VStack(spacing: DS.Spacing.s2) {
                Text("You're in!")
                    .font(.DS.title1)
                    .foregroundStyle(C.textPrimary)

                Text("You are \(result.pseudonym) in this league")
                    .font(.DS.subheadline)
                    .foregroundStyle(C.textSecondary)
            }

            playerCountCard(result: result)

            Text("League starts when 5 players have joined")
                .font(.DS.caption1)
                .foregroundStyle(C.textSecondary)
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
                    .foregroundStyle(C.textPrimary)
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(C.bgElevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(C.brandBlue)
                        .frame(
                            width: geo.size.width * progress,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(DS.Spacing.s4)
        .background(C.bgCard)
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
                .foregroundStyle(C.warningYellow)

            VStack(spacing: DS.Spacing.s2) {
                Text("Round started!")
                    .font(.DS.title1)
                    .foregroundStyle(C.textPrimary)

                Text("You are \(result.pseudonym)")
                    .font(.DS.subheadline)
                    .foregroundStyle(C.textSecondary)
            }

            infoChip(label: "League ID", value: result.leagueId)

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

    // MARK: - Helper sub-views

    func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.DS.subheadline)
                .foregroundStyle(C.textSecondary)
            Spacer()
            Text(value)
                .font(.DS.subheadline)
                .foregroundStyle(C.textPrimary)
        }
    }

    func ruleItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: icon)
                .font(.DS.caption1)
                .foregroundStyle(C.brandBlue)
                .frame(width: 16)
            Text(text)
                .font(.DS.caption1)
                .foregroundStyle(C.textSecondary)
        }
    }

    func errorBanner(message: String) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(C.errorRed)
            Text(message)
                .font(.DS.caption1)
                .foregroundStyle(C.textPrimary)
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(C.errorRed.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    func infoChip(label: String, value: String) -> some View {
        VStack(spacing: DS.Spacing.s1) {
            Text(label)
                .font(.DS.caption1)
                .foregroundStyle(C.textSecondary)
            Text(value)
                .font(.DS.headline)
                .foregroundStyle(C.textPrimary)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background(C.bgCard)
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
