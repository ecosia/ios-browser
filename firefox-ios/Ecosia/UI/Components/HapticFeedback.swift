// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit

/// Ecosia-owned wrapper for triggering impact haptic feedback.
public struct HapticFeedback {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - SwiftUI ViewModifier

private struct HapticFeedbackModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded { HapticFeedback.impact(style) }
        )
    }
}

public extension View {
    /// Adds an impact haptic feedback on tap without interfering with existing button actions.
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticFeedbackModifier(style: style))
    }
}
