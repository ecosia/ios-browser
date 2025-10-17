// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A circular progress bar that displays progress as a ring around content
@available(iOS 16.0, *)
public struct EcosiaAccountProgressBar: View {
    private let progress: Double
    private let size: CGFloat
    private let strokeWidth: CGFloat
    private let windowUUID: WindowUUID
    @State private var theme = EcosiaAccountProgressBarTheme()

    public init(
        progress: Double,
        size: CGFloat = .ecosia.space._6l,
        strokeWidth: CGFloat = 4,
        windowUUID: WindowUUID
    ) {
        self.progress = max(0.0, min(1.0, progress)) // Clamp between 0.0 and 1.0
        self.size = size
        self.strokeWidth = strokeWidth
        self.windowUUID = windowUUID
    }

    public var body: some View {
        ZStack {
            // Background ring (unfilled)
            Circle()
                .stroke(
                    theme.backgroundColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )

            // Progress ring (filled)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(
                    theme.progressColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
        .ecosiaThemed(windowUUID, $theme)
    }
}

// MARK: - Theme
struct EcosiaAccountProgressBarTheme: EcosiaThemeable {
    var progressColor = Color.primary
    var backgroundColor = Color.secondary

    mutating func applyTheme(theme: Theme) {
        progressColor = Color(theme.colors.ecosia.brandImpact)
        backgroundColor = Color(theme.colors.ecosia.borderDecorative)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAccountProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let windowUUID = WindowUUID()

        VStack(spacing: .ecosia.space._l) {
            // Different progress values
            EcosiaAccountProgressBar(
                progress: 0.25,
                windowUUID: windowUUID
            )

            EcosiaAccountProgressBar(
                progress: 0.75,
                windowUUID: windowUUID
            )

            EcosiaAccountProgressBar(
                progress: 1.0,
                windowUUID: windowUUID
            )

            // Different sizes
            EcosiaAccountProgressBar(
                progress: 0.5,
                size: .ecosia.space._8l,
                strokeWidth: 6,
                windowUUID: windowUUID
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
