// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Frosted-glass button style shared across all NTP elements (customize, account, AI search).
///
/// Applies `ultraThinMaterial` blur + a Gray90 dark tint that steps from 32 % at rest
/// to 64 % when pressed, with a translucent white border — matching the Ecosia NTP glass spec.
/// Pass any SwiftUI `Shape` to control the clip/border geometry (e.g. `Circle()`,
/// `RoundedRectangle(cornerRadius:)`).
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
        let tintOpacity: Double = configuration.isPressed ? 0.64 : 0.32
        configuration.label
            .background {
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    Self.glassTint.opacity(tintOpacity)
                }
            }
            .clipShape(shape)
            .overlay(shape.stroke(Self.glassBorder, lineWidth: 1))
    }
}
