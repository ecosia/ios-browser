// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Themed colours for the imitation glass used below iOS 26, for views themed with `ecosiaThemed`.
public struct NTPGlassTheme: EcosiaThemeable {
    public private(set) var tint = Color.clear
    public private(set) var tintPressed = Color.clear
    public private(set) var border = Color.clear

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        tint = Color(theme.colors.ecosia.buttonBgGlassStatic)
        tintPressed = Color(theme.colors.ecosia.buttonBgGlassStaticActive)
        border = Color(theme.colors.ecosia.borderGlassStatic)
    }
}

/// Glass button style for the NTP header buttons (customize, account, AI Chat).
///
/// On iOS 26 and later it uses the native interactive Liquid Glass, which adapts its
/// appearance to the content behind it.
/// Below iOS 26 it imitates glass with `ultraThinMaterial` blur + the `buttonBgGlassStatic` tint,
/// which steps to `buttonBgGlassStaticActive` when pressed, with a `borderGlassStatic` border.
/// Pass any SwiftUI `Shape` to control the glass geometry (e.g. `Circle()`, `Capsule()`).
@available(iOS 16.0, *)
public struct NTPGlassButtonStyle: ButtonStyle {
    private let shape: AnyShape
    private let theme: NTPGlassTheme

    public init<S: Shape>(_ shape: S, theme: NTPGlassTheme) {
        self.shape = AnyShape(shape)
        self.theme = theme
    }

    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            configuration.label
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            imitationGlass(configuration: configuration)
        }
    }

    private func imitationGlass(configuration: Configuration) -> some View {
        configuration.label
            .background {
                // Ecosia: Force the dark-mode variant of ultraThinMaterial so the glass always reads
                // against the NTP wallpaper regardless of the system color scheme.
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    configuration.isPressed ? theme.tintPressed : theme.tint
                }
                .environment(\.colorScheme, .dark)
            }
            .clipShape(shape)
            .overlay(shape.stroke(theme.border, lineWidth: 1))
    }
}

/// Themed colours for the solid NTP header buttons, for views themed with `ecosiaThemed`.
public struct NTPSolidButtonTheme: EcosiaThemeable {
    public private(set) var background = Color.clear
    public private(set) var backgroundPressed = Color.clear

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        // Not buttonBackgroundSecondary: in dark mode it matches the plain NTP background, so the button disappears.
        background = Color(theme.colors.ecosia.backgroundElevation1)
        backgroundPressed = Color(theme.colors.ecosia.buttonBackgroundSecondaryActive)
    }
}

/// Solid secondary button style for the NTP header buttons when no wallpaper is behind them.
public struct NTPSolidButtonStyle<S: Shape>: ButtonStyle {
    private let shape: S
    private let theme: NTPSolidButtonTheme

    public init(_ shape: S, theme: NTPSolidButtonTheme) {
        self.shape = shape
        self.theme = theme
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? theme.backgroundPressed : theme.background)
            .clipShape(shape)
    }
}
