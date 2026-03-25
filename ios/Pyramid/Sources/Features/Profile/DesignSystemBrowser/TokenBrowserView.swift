#if DEBUG
import SwiftUI

struct TokenBrowserView: View {
    enum Category: String, CaseIterable {
        case colours = "Colours"
        case typography = "Type"
        case spacing = "Spacing"
        case radius = "Radius"
        case shadows = "Shadows"
        case gradients = "Gradients"
        case icons = "Icons"
    }

    @State private var selectedCategory: Category = .colours

    var body: some View {
        VStack(spacing: 0) {
            categoryPicker
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s60
                ) {
                    switch selectedCategory {
                    case .colours:
                        colorSection
                    case .typography:
                        typographySection
                    case .spacing:
                        spacingSection
                    case .radius:
                        radiusSection
                    case .shadows:
                        shadowSection
                    case .gradients:
                        gradientSection
                    case .icons:
                        iconSection
                    }
                }
                .padding(Theme.Spacing.s40)
            }
        }
    }

    private var categoryPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: Theme.Spacing.s20) {
                    ForEach(
                        Category.allCases,
                        id: \.self
                    ) { cat in
                        Button {
                            withAnimation(
                                .easeInOut(duration: 0.2)
                            ) {
                                selectedCategory = cat
                            }
                        } label: {
                            Text(cat.rawValue)
                                .font(
                                    Theme.Typography
                                        .label01
                                )
                                .foregroundStyle(
                                    selectedCategory == cat
                                        ? Theme.Color
                                            .Content
                                            .Text
                                            .default
                                        : Theme.Color
                                            .Content
                                            .Text.subtle
                                )
                                .padding(
                                    .horizontal,
                                    Theme.Spacing.s30
                                )
                                .padding(
                                    .vertical,
                                    Theme.Spacing.s20
                                )
                                .background(
                                    selectedCategory == cat
                                        ? Theme.Color
                                            .Surface
                                            .Background
                                            .highlight
                                        : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .id(cat)
                    }
                }
                .padding(
                    .horizontal, Theme.Spacing.s40
                )
                .padding(
                    .vertical, Theme.Spacing.s20
                )
            }
            .onChange(of: selectedCategory) { newCat in
                withAnimation {
                    proxy.scrollTo(
                        newCat, anchor: .center
                    )
                }
            }
        }
    }
}

// MARK: - Color Token Row

struct ColorTokenRow: View {
    let name: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.s30) {
            RoundedRectangle(cornerRadius: Theme.Radius.r10)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.r10)
                        .strokeBorder(
                            Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
            Text(name)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Spacer()
            Text(color.hexString)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
                .monospacedDigit()
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.h3)
            .foregroundStyle(Theme.Color.Content.Text.default)
    }
}

struct SubsectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Typography.subhead)
            .foregroundStyle(Theme.Color.Content.Text.subtle)
    }
}

// MARK: - Color Group

struct ColorGroup: View {
    let title: String
    let swatches: [(String, Color)]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            SubsectionHeader(title: title)
            VStack(spacing: Theme.Spacing.s10) {
                ForEach(swatches, id: \.0) { name, color in
                    ColorTokenRow(name: name, color: color)
                }
            }
        }
    }
}

// MARK: - Color Hex Helper

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        if alpha < 1.0 {
            return String(
                format: "#%02X%02X%02X/%d%%",
                Int(red * 255),
                Int(green * 255),
                Int(blue * 255),
                Int(alpha * 100)
            )
        }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

#Preview {
    NavigationStack {
        TokenBrowserView()
    }
}
#endif
