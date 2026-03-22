import SwiftUI

// MARK: - WalletView

struct WalletView: View {
    @StateObject var viewModel = WalletViewModel()
    @State private var showPendingInfo = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.Surface.Background.page.ignoresSafeArea()

                if viewModel.isLoading && viewModel.wallet == nil {
                    ProgressView()
                        .tint(Theme.Color.Content.Text.default)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            balanceHeader
                            transactionHistorySection
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $viewModel.showTopUpSheet) {
            TopUpSheet(isPresented: $viewModel.showTopUpSheet)
        }
        .sheet(isPresented: $viewModel.showWithdrawSheet) {
            WithdrawSheet(
                isPresented: $viewModel.showWithdrawSheet,
                withdrawablePence: viewModel.wallet?.withdrawablePence ?? 0,
                withdrawableFormatted: viewModel.wallet?.withdrawableFormatted ?? "\u{a3}0.00",
                onWithdraw: { amount in
                    await viewModel.requestWithdrawal(amountPence: amount)
                }
            )
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Balance Header

    private var balanceHeader: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Available to Play")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                Text(viewModel.wallet?.availableToPlayFormatted ?? "–")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(Theme.Color.Content.Text.default)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "Available to play, \(viewModel.wallet?.availableToPlayFormatted ?? "unknown")"
            )

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("Withdrawable")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    let withdrawable = viewModel.wallet?.withdrawablePence ?? 0
                    Text(viewModel.wallet?.withdrawableFormatted ?? "\u{2013}")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(
                            withdrawable > 0
                                ? Theme.Color.Status.Success.resting
                                : Theme.Color.Content.Text.subtle
                        )
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Withdrawable, \(viewModel.wallet?.withdrawableFormatted ?? "none")"
                )

                Rectangle()
                    .fill(Theme.Color.Border.default)
                    .frame(width: 1, height: 32)
                    .accessibilityHidden(true)

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Pending")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Color.Content.Text.disabled)
                        Button {
                            showPendingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Color.Content.Text.disabled)
                        }
                        .popover(isPresented: $showPendingInfo) {
                            pendingInfoPopoverContent
                        }
                    }
                    Text(viewModel.wallet?.pendingFormatted ?? "–")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Pending, \(viewModel.wallet?.pendingFormatted ?? "none")"
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button("TOP UP") {
                    viewModel.showTopUpSheet = true
                }
                .dsStyle(.primary)

                let withdrawable =
                    viewModel.wallet?.withdrawablePence ?? 0
                Button("WITHDRAW") {
                    viewModel.showWithdrawSheet = true
                }
                .dsStyle(.secondary)
                .disabled(withdrawable == 0)
            }

            Text("Withdrawals processed within 3–5 business days")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Pending Info Popover

    @ViewBuilder private var pendingInfoPopoverContent: some View {
        let content = Text("Funds awaiting settlement from active leagues")
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Color.Content.Text.default)
            .padding(12)
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }

}
