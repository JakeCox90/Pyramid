import SwiftUI

// MARK: - Empty State (Figma 32:4432)

extension MatchCard {
    static func empty(
        isLocked: Bool,
        onMakePick: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 0) {
            Spacer()
            emptyPlaceholder
            Spacer()
            emptyDivider
            emptyBottom(
                isLocked: isLocked,
                onMakePick: onMakePick
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 446)
        .clipShape(
            RoundedRectangle(cornerRadius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Color.white.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    /// Figma: Frame 22 — centered at y~104, 225px wide
    private static var emptyPlaceholder: some View {
        VStack(spacing: 8) {
            // Figma: Shield Icon 24dp — 66x66, #FFF 20%
            Image("shield-question")
                .renderingMode(.template)
                .resizable()
                .frame(width: 66, height: 66)
                .foregroundStyle(
                    Color.white.opacity(0.2)
                )

            // Figma: H3, #FFF 30%
            Text("No selection yet")
                .font(Theme.Typography.h3)
                .foregroundStyle(
                    Color.white.opacity(0.3)
                )

            // Figma: Label02, #FFF 30%, 225px wide
            Text(
                "Select a team before the gameweek begins or get eliminated"
            )
            .font(Theme.Typography.label02)
            .foregroundStyle(
                Color.white.opacity(0.3)
            )
            .multilineTextAlignment(.center)
            .frame(width: 225)
        }
    }

    /// Figma: Vector 2 — 1px divider at y=354
    private static var emptyDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(height: 1)
    }

    /// Figma: Frame 13 — 24px padding, 20px gap
    @ViewBuilder
    private static func emptyBottom(
        isLocked: Bool,
        onMakePick: (() -> Void)?
    ) -> some View {
        if isLocked {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                Text("LOCKED")
                    .font(Theme.Typography.label01)
            }
            .foregroundStyle(
                Color.white.opacity(0.4)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white.opacity(0.1))
            .overlay(
                Capsule()
                    .stroke(
                        Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        } else if let onMakePick {
            // Figma: Button Variant=Primary — #FFC758, 294x44
            Button(
                "MAKE YOUR PICK",
                action: onMakePick
            )
            .themed(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }
}
