import SwiftUI

// MARK: - Withdraw Sheet

struct WithdrawSheet: View {
    @Binding var isPresented: Bool
    let withdrawablePence: Int
    let withdrawableFormatted: String
    let onWithdraw: (Int) async -> Void

    @State private var amountText = ""
    @State private var isSubmitting = false
    @State private var localError: String?

    private let minimumPence = 2000  // £20

    private var amountPence: Int? {
        guard let value = Double(amountText), value > 0 else { return nil }
        return Int(value * 100)
    }

    private var validationError: String? {
        guard let pence = amountPence else { return nil }
        if pence < minimumPence {
            return "Minimum withdrawal is £20.00."
        }
        if pence > withdrawablePence {
            return "Amount exceeds your withdrawable balance."
        }
        return nil
    }

    private var withdrawEnabled: Bool {
        amountPence != nil && validationError == nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.DS.Background.primary.ignoresSafeArea()

                VStack(spacing: DS.Spacing.s6) {
                    balanceDisplay
                    amountInput

                    if let error = localError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.DS.Semantic.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DS.Spacing.pageMargin)
                    }

                    Spacer()

                    withdrawButton
                }
                .padding(.top, DS.Spacing.s2)
            }
            .navigationTitle("Withdraw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(Color.DS.Text.secondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Balance Display

    private var balanceDisplay: some View {
        VStack(spacing: DS.Spacing.s1) {
            Text("Available to withdraw")
                .font(.subheadline)
                .foregroundStyle(Color.DS.Text.secondary)
            Text(withdrawableFormatted)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.DS.Semantic.success)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s5)
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    // MARK: - Amount Input

    private var amountInput: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("Amount to withdraw")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.DS.Text.secondary)

            HStack {
                Text("£")
                    .font(.headline)
                    .foregroundStyle(Color.DS.Text.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.headline)
                    .foregroundStyle(Color.DS.Text.primary)
            }
            .padding(14)
            .background(Color.DS.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.DS.Semantic.error)
            } else {
                Text("Minimum withdrawal: £20.00")
                    .font(.caption)
                    .foregroundStyle(Color.DS.Text.tertiary)
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    // MARK: - Withdraw Button

    private var withdrawButton: some View {
        Button {
            guard let pence = amountPence else { return }
            isSubmitting = true
            localError = nil
            Task {
                await onWithdraw(pence)
                isSubmitting = false
            }
        } label: {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Withdraw")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s4)
            .background(
                withdrawEnabled
                    ? Color.DS.Semantic.error
                    : Color.DS.Background.elevated
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .disabled(!withdrawEnabled)
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.bottom, DS.Spacing.s4)
    }
}
