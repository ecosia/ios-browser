// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Glass button style for the NTP header buttons (customize, account, AI Chat).
///
/// On iOS 26 and later it uses the native interactive Liquid Glass, which adapts its
/// appearance to the content behind it.
/// Below iOS 26 it imitates glass with `ultraThinMaterial` blur + a Gray90 dark tint that
/// steps from 32 % at rest to 64 % when pressed, with a translucent white border.
/// Pass any SwiftUI `Shape` to control the glass geometry (e.g. `Circle()`, `Capsule()`).
@available(iOS 16.0, *)
public struct NTPGlassButtonStyle: ButtonStyle {
    private let shape: AnyShape

    // Gray90 (#1A1A1A) — same primitive used by EcosiaColor.Gray90 in the Client target.
    private static let glassTint = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)
    // White at ~24 % opacity — matches borderGlassStatic used on impact cells.
    private static let glassBorder = Color.white.opacity(0x3D / 255.0)

    public init<S: Shape>(_ shape: S) {
        self.shape = AnyShape(shape)
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
        let tintOpacity: Double = configuration.isPressed ? 0.64 : 0.32
        return configuration.label
            .background {
                // Ecosia: Force the dark-mode variant of ultraThinMaterial so the glass always reads
                // against the NTP wallpaper regardless of the system color scheme.
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    Self.glassTint.opacity(tintOpacity)
                }
                .environment(\.colorScheme, .dark)
            }
            .clipShape(shape)
            .overlay(shape.stroke(Self.glassBorder, lineWidth: 1))
    }
}
