import SwiftUI

struct GameweekOverviewView: View {
    @ObservedObject var viewModel: GameweekStoryViewModel
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
                    headerSection
                    statsSection
                    picksSection
                }
                .padding(Theme.Spacing.s60)
            }
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("GW\(viewModel.gameweek) Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Replay Story") {
                        dismiss()
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Primary.resting)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.Primary.resting)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Gameweek \(viewModel.gameweek)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Text(viewModel.leagueName)
                .font(Theme.Typography.h3)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }

    private var statsSection: some View {
        let survived = viewModel.cards.compactMap { card -> Int? in
            if case let .standing(players, _, _) = card { return players.count }
            return nil
        }.first ?? 0

        let eliminated = viewModel.cards.compactMap { card -> Int? in
            if case let .eliminated(players) = card { return players.count }
            return nil
        }.first ?? 0

        return HStack(spacing: Theme.Spacing.s40) {
            statBox(label: "Survived", count: survived, color: Theme.Color.Status.Success.resting)
            statBox(label: "Eliminated", count: eliminated, color: Theme.Color.Status.Error.resting)
        }
    }

    private func statBox(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.s10) {
            Text("\(count)")
                .font(Theme.Typography.h3)
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
    }

    private var picksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s30) {
            Text("All Picks")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)

            ForEach(viewModel.cards, id: \.id) { card in
                if case let .eliminated(players) = card {
                    ForEach(players) { player in
                        pickRow(
                            name: player.displayName,
                            team: player.teamName,
                            result: player.result,
                            survived: false
                        )
                    }
                }
            }

            ForEach(viewModel.cards, id: \.id) { card in
                if case let .standing(players, _, _) = card {
                    ForEach(players) { player in
                        pickRow(name: player.displayName, team: "", result: "Survived", survived: true)
                    }
                }
            }
        }
    }

    private func pickRow(name: String, team: String, result: String, survived: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                if !team.isEmpty {
                    Text(team)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
            }
            Spacer()
            Text(result)
                .font(Theme.Typography.caption)
                .foregroundStyle(survived ? Theme.Color.Status.Success.resting : Theme.Color.Status.Error.resting)
        }
        .padding(Theme.Spacing.s30)
    }
}
