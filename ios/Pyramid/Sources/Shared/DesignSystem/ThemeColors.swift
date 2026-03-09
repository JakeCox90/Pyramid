import SwiftUI

private func adaptive(_ light: String, _ dark: String) -> SwiftUI.Color {
    Theme.color(light: light, dark: dark)
}

private func solid(_ hex: String) -> SwiftUI.Color {
    Theme.color(light: hex, dark: hex)
}

private func adaptiveUI(
    light: UIColor, dark: UIColor
) -> SwiftUI.Color {
    Theme.color(light: light, dark: dark)
}

private func rgba(
    _ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat
) -> UIColor {
    Theme.rgbaUIColor(red, green, blue, alpha)
}

// MARK: - Theme.Color — Semantic color tokens

extension Theme {
    enum Color {
        enum Primary {
            static let resting = solid("7695EF")
            static let pressed = solid("3B62D0")
            static let selected = adaptive("7695EF", "20387D")
            static let text = solid("FFFFFF")
            static let disabled = adaptiveUI(
                light: rgba(32, 39, 59, 0.1), dark: rgba(255, 255, 255, 0.1)
            )
        }
        enum Secondary {
            static let resting = adaptiveUI(
                light: rgba(32, 39, 59, 0.1), dark: rgba(255, 255, 255, 0.1)
            )
            static let pressed = adaptiveUI(
                light: rgba(32, 39, 59, 0.2), dark: rgba(255, 255, 255, 0.2)
            )
            static let selected = adaptiveUI(
                light: rgba(32, 39, 59, 0.3), dark: rgba(255, 255, 255, 0.3)
            )
            static let text = adaptive("20273B", "FFFFFF")
            static let disabled = adaptiveUI(
                light: rgba(32, 39, 59, 0.1), dark: rgba(255, 255, 255, 0.1)
            )
        }
        enum Content {
            enum Text {
                static let `default` = adaptive("1D1D1B", "FFFFFF")
                static let subtle = adaptiveUI(
                    light: Theme.hexToUIColor("878787"),
                    dark: rgba(255, 255, 255, 0.7)
                )
                static let contrast = adaptive("FFFFFF", "20273B")
                static let disabled = adaptiveUI(
                    light: Theme.hexToUIColor("B8B8B8"),
                    dark: rgba(255, 255, 255, 0.4)
                )
            }
            enum Link {
                static let resting = adaptive("20273B", "FFFFFF")
                static let pressed = adaptiveUI(
                    light: rgba(32, 39, 59, 0.4), dark: rgba(255, 255, 255, 0.6)
                )
                static let contrast = adaptive("FFFFFF", "FFFFFF")
                static let disabled = adaptiveUI(
                    light: Theme.hexToUIColor("B8B8B8"),
                    dark: rgba(255, 255, 255, 0.4)
                )
            }
        }
        enum Surface {
            enum Background {
                static let container = adaptive("FFFFFF", "2C3354")
                static let highlight = adaptiveUI(
                    light: rgba(255, 255, 255, 0.1), dark: rgba(255, 255, 255, 0.1)
                )
                static let page = adaptive("F3F3F3", "20273B")
                static let disabled = adaptiveUI(
                    light: Theme.hexToUIColor("E3E3E3"),
                    dark: rgba(255, 255, 255, 0.4)
                )
                static let transparent = adaptiveUI(
                    light: rgba(255, 255, 255, 0), dark: rgba(44, 51, 84, 0)
                )
            }
            enum Overlay {
                static let `default` = adaptiveUI(
                    light: rgba(32, 39, 59, 0.5), dark: rgba(32, 39, 59, 0.5)
                )
                static let heavy = adaptiveUI(
                    light: rgba(32, 39, 59, 0.7), dark: rgba(32, 39, 59, 0.7)
                )
            }
            enum Skeleton {
                static let `default` = adaptiveUI(
                    light: rgba(32, 39, 59, 0.2), dark: rgba(255, 255, 255, 0.2)
                )
                static let heavy = adaptiveUI(
                    light: rgba(32, 39, 59, 0.3), dark: rgba(255, 255, 255, 0.3)
                )
            }
        }
        enum Border {
            static let `default` = adaptiveUI(
                light: rgba(32, 39, 59, 0.1), dark: rgba(255, 255, 255, 0.2)
            )
            static let heavy = adaptiveUI(
                light: rgba(32, 39, 59, 0.4), dark: rgba(255, 255, 255, 0.4)
            )
        }
        enum Status {
            enum Info {
                static let resting = solid("5B6FD3")
                static let pressed = solid("3F52A9")
                static let text = solid("FFFFFF")
                static let disabled = solid("F3F3F3")
                static let border = adaptiveUI(
                    light: rgba(255, 255, 255, 0.3), dark: rgba(255, 255, 255, 0.3)
                )
                static let subtle = adaptiveUI(
                    light: Theme.hexToUIColor("CFFAFE"),
                    dark: rgba(91, 111, 211, 0.15)
                )
            }
            enum Error {
                static let resting = solid("FF494B")
                static let pressed = solid("D43A3C")
                static let text = solid("FFFFFF")
                static let disabled = solid("F3F3F3")
                static let border = adaptiveUI(
                    light: rgba(255, 255, 255, 0.3), dark: rgba(255, 255, 255, 0.3)
                )
                static let subtle = adaptiveUI(
                    light: Theme.hexToUIColor("FEE2E2"),
                    dark: rgba(255, 73, 75, 0.15)
                )
            }
            enum Success {
                static let resting = solid("56CC8A")
                static let pressed = solid("46AB72")
                static let text = solid("FFFFFF")
                static let disabled = solid("F3F3F3")
                static let border = adaptiveUI(
                    light: rgba(255, 255, 255, 0.3), dark: rgba(255, 255, 255, 0.3)
                )
                static let subtle = adaptiveUI(
                    light: Theme.hexToUIColor("DCFCE7"),
                    dark: rgba(86, 204, 138, 0.15)
                )
            }
            enum Warning {
                static let resting = solid("E67E23")
                static let pressed = solid("C76E1D")
                static let text = solid("FFFFFF")
                static let disabled = solid("F3F3F3")
                static let border = adaptiveUI(
                    light: rgba(255, 255, 255, 0.3), dark: rgba(255, 255, 255, 0.3)
                )
                static let subtle = adaptiveUI(
                    light: Theme.hexToUIColor("FEF3C7"),
                    dark: rgba(230, 126, 35, 0.15)
                )
            }
            enum Breaking {
                static let resting = solid("F9D654")
                static let pressed = solid("DCBD47")
                static let text = adaptive("1D1D1B", "1D1D1B")
                static let disabled = solid("F3F3F3")
                static let border = adaptiveUI(
                    light: rgba(255, 255, 255, 0.3), dark: rgba(255, 255, 255, 0.3)
                )
            }
        }
    }
}
