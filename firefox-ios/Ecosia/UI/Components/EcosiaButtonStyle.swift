// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Button style that shows highlight state during tap
public struct EcosiaButtonStyle: ButtonStyle {
    public enum Style {
        case bare
        case outline
    }

    let theme: Theme
    let style: Style
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    public init(theme: Theme, style: Style = .outline, cornerRadius: CGFloat = 22, borderWidth: CGFloat = 1) {
        self.theme = theme
        self.style = style
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        switch style {
        case .bare:
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(configuration.isPressed
                            ? theme.colors.ecosia.buttonBackgroundTransparentActive
                            : .clear))
                )
        case .outline:
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(theme.colors.ecosia.borderDecorative), lineWidth: borderWidth)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color(configuration.isPressed
                                    ? theme.colors.ecosia.buttonBackgroundSecondaryActive
                                    : theme.colors.ecosia.buttonBackgroundSecondary))
                        )
                )
        }
    }
}
