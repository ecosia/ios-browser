// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Glass button style for the NTP header buttons (customize, account, AI Chat).
///
/// On iOS 26 and later it uses the native interactive Liquid Glass, which takes its light or
/// dark look from the interface style.
/// Below iOS 26 it imitates glass with `ultraThinMaterial` blur + a tint that steps from 32 %
/// at rest to 64 % when pressed, with a translucent border. The imitation is dark unless
/// `followsColorScheme` is set, in which case it is light in the light colour scheme.
/// Pass any SwiftUI `Shape` to control the glass geometry (e.g. `Circle()`, `Capsule()`).
@available(iOS 16.0, *)
public struct NTPGlassButtonStyle: ButtonStyle {
    private let shape: AnyShape
    private let followsColorScheme: Bool
    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    public init<S: Shape>(_ shape: S, followsColorScheme: Bool = false) {
        self.shape = AnyShape(shape)
        self.followsColorScheme = followsColorScheme
    }

    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            configuration.label
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            imitationGlass(configuration: configuration)
        }
    }

    private var imitation: NTPImitationGlass {
        followsColorScheme && colorScheme == .light ? .light : .dark
    }

    private func imitationGlass(configuration: Configuration) -> some View {
        let imitation = imitation
        let tintOpacity: Double = configuration.isPressed ? 0.64 : 0.32
        return configuration.label
            .background {
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    imitation.tint.opacity(tintOpacity)
                }
                .environment(\.colorScheme, imitation.blurColorScheme)
            }
            .clipShape(shape)
            .overlay(shape.stroke(imitation.border, lineWidth: 1))
    }
}

/// The custom glass used below iOS 26.
struct NTPImitationGlass {
    let blurColorScheme: ColorScheme
    let tint: Color
    let border: Color

    // Gray90 (#1A1A1A) tint and white border at ~24 % — matches borderGlassStatic used on impact cells.
    static let dark = NTPImitationGlass(
        blurColorScheme: .dark,
        tint: Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255),
        border: Color.white.opacity(0x3D / 255.0)
    )

    // A white border would disappear on light backgrounds, so light glass uses a faint dark one.
    static let light = NTPImitationGlass(
        blurColorScheme: .light,
        tint: Color.white,
        border: Color.black.opacity(0.08)
    )
}
