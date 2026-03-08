import SwiftUI

// MARK: - Sheet Colours (local constants)

private let bgPrimary = Color(hex: "0A0A0A")
private let bgCard = Color(hex: "1C1C1E")
private let bgElevated = Color(hex: "2C2C2E")
private let textPrimary = Color.white
private let textSecondary = Color.white.opacity(0.6)
private let textTertiary = Color.white.opacity(0.3)
private let brandBlue = Color(hex: "1A56DB")
private let successGreen = Color(hex: "30D158")
private let errorRed = Color(hex: "FF453A")
private let warningYellow = Color(hex: "FFD60A")

// MARK: - Top-Up Sheet

struct TopUpSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedAmountPence: Int?
    @State private var customAmountText = ""
    @FocusState private var isCustomFieldFocused: Bool

    private let quickAmounts = [500, 1000, 2500, 5000]  // £5, £10, £25, £50

    private var resolvedAmountPence: Int? {
        if let selected = selectedAmountPence { return selected }
        guard let value = Double(customAmountText), value >= 5 else { return nil }
        return Int(value * 100)
    }

    private var continueEnabled: Bool {
        guard let amount = resolvedAmountPence else { return false }
        return amount >= 500  // £5 minimum
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Stripe GATE banner
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(warningYellow)
                        Text("Payment processing coming soon — Stripe integration pending (PYR-25)")
                            .font(.caption)
                            .foregroundStyle(warningYellow)
                    }
                    .padding(12)
                    .background(warningYellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)

                    // Quick-pick amounts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select an amount")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(textSecondary)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(quickAmounts, id: \.self) { pence in
                                let label = String(format: "£%.0f", Double(pence) / 100)
                                Button {
                                    selectedAmountPence = pence
                                    customAmountText = ""
                                    isCustomFieldFocused = false
                                } label: {
                                    Text(label)
                                        .font(.headline)
                                        .foregroundStyle(selectedAmountPence == pence ? .white : textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(selectedAmountPence == pence ? brandBlue : bgElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Custom amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or enter a custom amount")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(textSecondary)

                        HStack {
                            Text("£")
                                .font(.headline)
                                .foregroundStyle(textSecondary)
                            TextField("0.00", text: $customAmountText)
                                .keyboardType(.decimalPad)
                                .font(.headline)
                                .foregroundStyle(textPrimary)
                                .focused($isCustomFieldFocused)
                                .onChange(of: customAmountText) { _, _ in
                                    if !customAmountText.isEmpty {
                                        selectedAmountPence = nil
                                    }
                                }
                        }
                        .padding(14)
                        .background(bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("Minimum top-up: £5.00")
                            .font(.caption)
                            .foregroundStyle(textTertiary)
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    Button {
                        // TODO: PYR-25 GATE — wire up Stripe PaymentSheet here
                        isPresented = false
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(continueEnabled ? brandBlue : bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!continueEnabled)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Top Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

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
        if pence < minimumPence { return "Minimum withdrawal is £20.00." }
        if pence > withdrawablePence { return "Amount exceeds your withdrawable balance." }
        return nil
    }

    private var withdrawEnabled: Bool {
        amountPence != nil && validationError == nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Withdrawable balance display
                    VStack(spacing: 4) {
                        Text("Available to withdraw")
                            .font(.subheadline)
                            .foregroundStyle(textSecondary)
                        Text(withdrawableFormatted)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(successGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                    // Amount input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount to withdraw")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(textSecondary)

                        HStack {
                            Text("£")
                                .font(.headline)
                                .foregroundStyle(textSecondary)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.headline)
                                .foregroundStyle(textPrimary)
                        }
                        .padding(14)
                        .background(bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let error = validationError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(errorRed)
                        } else {
                            Text("Minimum withdrawal: £20.00")
                                .font(.caption)
                                .foregroundStyle(textTertiary)
                        }
                    }
                    .padding(.horizontal, 16)

                    if let error = localError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(errorRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    Spacer()

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
                        .padding(.vertical, 16)
                        .background(withdrawEnabled ? errorRed : bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!withdrawEnabled)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Withdraw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
