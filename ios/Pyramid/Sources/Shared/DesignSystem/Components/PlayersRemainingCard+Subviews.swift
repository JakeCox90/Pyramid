import SwiftUI

// MARK: - Avatar Rows

extension PlayersRemainingCard {
    var survivorAvatars: some View {
        let visible = Array(
            survivors
                .sorted {
                    $0.userId == currentUserId ? true
                        : $1.userId == currentUserId
                        ? false
                        : $0.displayName < $1.displayName
                }
                .prefix(Self.maxSurvivors)
        )
        let overflow = survivors.count - visible.count

        return HStack(spacing: Theme.Spacing.s20) {
            ForEach(visible) { member in
                let isCurrent =
                    member.userId == currentUserId
                Group {
                    if isCurrent
                        && member.avatarURL == nil
                    {
                        currentUserInitials(
                            name: member.displayName
                        )
                    } else {
                        Avatar(
                            name: member.displayName,
                            imageURL: member.avatarURL,
                            size: .small
                        )
                    }
                }
                .overlay(
                    Circle()
                        .stroke(
                            Theme.Color.Status.Success
                                .resting,
                            lineWidth: 2
                        )
                )
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text.subtle
                    )
            }
        }
    }

    private func currentUserInitials(
        name: String
    ) -> some View {
        Text(Avatar.initials(for: name))
            .font(AvatarSize.small.font)
            .fontWeight(.semibold)
            .foregroundStyle(
                Theme.Color.Content.Text.contrast
            )
            .frame(
                width: AvatarSize.small.dimension,
                height: AvatarSize.small.dimension
            )
            .background(Theme.Color.Primary.resting)
            .clipShape(Circle())
    }

    var eliminatedAvatars: some View {
        let sorted = eliminated.sorted {
            $0.userId == currentUserId ? true
                : $1.userId == currentUserId ? false
                : $0.displayName < $1.displayName
        }
        let visible = Array(
            sorted.prefix(Self.maxEliminated)
        )
        let overflow = eliminated.count - visible.count

        return HStack(spacing: Theme.Spacing.s20) {
            ForEach(visible) { member in
                let isCurrentUser =
                    member.userId == currentUserId
                let size: CGFloat = isCurrentUser ? 24 : 20

                Text(
                    String(
                        member.displayName.prefix(1)
                    )
                    .uppercased()
                )
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    isCurrentUser
                        ? Theme.Color.Status.Error
                            .resting
                        : Theme.Color.Content.Text
                            .disabled
                )
                .frame(width: size, height: size)
                .background(
                    isCurrentUser
                        ? Theme.Color.Status.Error
                            .subtle
                        : Theme.Color.Surface.Background
                            .elevated
                )
                .clipShape(Circle())
                .overlay(
                    isCurrentUser
                        ? Circle().stroke(
                            Theme.Color.Status.Error
                                .resting,
                            lineWidth: 1.5
                        )
                        : nil
                )
                .opacity(isCurrentUser ? 1 : 0.5)
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(
                        Theme.Color.Content.Text
                            .disabled
                    )
            }
        }
    }
}

// MARK: - Stats Row

extension PlayersRemainingCard {
    var statsRow: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Color.Border.light)
                .frame(height: 1)

            HStack(spacing: 0) {
                statItem(
                    value: "\(eliminatedThisWeek)",
                    label: "eliminated\nthis week",
                    color: Theme.Color.Status.Error
                        .resting
                )

                statDivider

                statItem(
                    value: "\(percentage)%",
                    label: "of the field\nremain",
                    color: isEliminated
                        ? Theme.Color.Content.Text
                            .subtle
                        : Theme.Color.Status.Success
                            .resting
                )

                statDivider

                statItem(
                    value: "\(survivalStreak)",
                    label: isEliminated
                        ? "weeks\nyou lasted"
                        : "weeks\nsurvived",
                    color: Theme.Color.Content.Text
                        .default
                )
            }
            .fixedSize(
                horizontal: false, vertical: true
            )
            .padding(.top, Theme.Spacing.s30)
        }
    }

    func statItem(
        value: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text(value)
                .font(Theme.Typography.subhead)
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.Color.Border.light)
            .frame(width: 1)
    }
}
