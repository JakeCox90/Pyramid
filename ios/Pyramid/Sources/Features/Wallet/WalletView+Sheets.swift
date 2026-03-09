import SwiftUI

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
                Color.DS.Background.primary.ignoresSafeArea()

                VStack(spacing: DS.Spacing.s6) {
                    // Stripe GATE banner
                    HStack(spacing: DS.Spacing.s2) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.DS.Semantic.warning)
                        Text(
                            "Payment processing coming soon"
                                + " — Stripe integration pending (PYR-25)"
                        )
                        .font(.caption)
                        .foregroundStyle(Color.DS.Semantic.warning)
                    }
                    .padding(DS.Spacing.s3)
                    .background(Color.DS.Semantic.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                    .padding(.horizontal, DS.Spacing.pageMargin)

                    quickPickSection
                    customAmountSection

                    Spacer()

                    continueButton
                }
                .padding(.top, DS.Spacing.s2)
            }
            .navigationTitle("Top Up")
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

    // MARK: - Quick Pick

    private var quickPickSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Select an amount")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.DS.Text.secondary)
                .padding(.horizontal, DS.Spacing.pageMargin)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: DS.Spacing.s3
            ) {
                ForEach(quickAmounts, id: \.self) { pence in
                    quickAmountButton(pence: pence)
                }
            }
            .padding(.horizontal, DS.Spacing.pageMargin)
        }
    }

    private func quickAmountButton(pence: Int) -> some View {
        let label = String(format: "£%.0f", Double(pence) / 100)
        return Button {
            selectedAmountPence = pence
            customAmountText = ""
            isCustomFieldFocused = false
        } label: {
            Text(label)
                .font(.headline)
                .foregroundStyle(
                    selectedAmountPence == pence
                        ? .white : Color.DS.Text.primary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s4)
                .background(
                    selectedAmountPence == pence
                        ? Color.DS.Brand.primary
                        : Color.DS.Background.elevated
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    // MARK: - Custom Amount

    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("Or enter a custom amount")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.DS.Text.secondary)

            HStack {
                Text("£")
                    .font(.headline)
                    .foregroundStyle(Color.DS.Text.secondary)
                TextField("0.00", text: $customAmountText)
                    .keyboardType(.decimalPad)
                    .font(.headline)
                    .foregroundStyle(Color.DS.Text.primary)
                    .focused($isCustomFieldFocused)
                    .onChange(of: customAmountText) { newValue in
                        if !newValue.isEmpty {
                            selectedAmountPence = nil
                        }
                    }
            }
            .padding(14)
            .background(Color.DS.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))

            Text("Minimum top-up: £5.00")
                .font(.caption)
                .foregroundStyle(Color.DS.Text.tertiary)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            // TODO: PYR-25 GATE — wire up Stripe PaymentSheet
            isPresented = false
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s4)
                .background(
                    continueEnabled
                        ? Color.DS.Brand.primary
                        : Color.DS.Background.elevated
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .disabled(!continueEnabled)
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.bottom, DS.Spacing.s4)
    }
}
