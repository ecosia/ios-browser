// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A reusable seed count component that displays the seed icon and animated count.
/// Displays counts 0-999 normally, and "999+" for counts of 1000 or more.
/// Screen readers always receive the actual count for accessibility.
@available(iOS 16.0, *)
public struct EcosiaSeedView: View {
    private let seedCount: Int
    private let iconSize: CGFloat
    private let spacing: CGFloat
    private let enableAnimation: Bool
    private let windowUUID: WindowUUID
    @State private var bounceScale: CGFloat = 1.0
    @State private var theme = EcosiaSeedViewTheme()

    private struct UX {
        static let bounceScaleMin: CGFloat = 0.75
        static let bounceAnimationDuration: TimeInterval = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.45
    }

    public init(
        seedCount: Int,
        iconSize: CGFloat = .ecosia.space._1l,
        spacing: CGFloat = .ecosia.space._1s,
        enableAnimation: Bool = true,
        windowUUID: WindowUUID
    ) {
        self.seedCount = seedCount
        self.iconSize = iconSize
        self.spacing = spacing
        self.enableAnimation = enableAnimation
        self.windowUUID = windowUUID
    }

    private var displayedSeedCount: String {
        if seedCount > 999 {
            return String(format: .localized(.numberAsStringWithPlusSymbol), "999")
        }
        return "\(seedCount)"
    }

    private var accessibilityLabel: String {
        String(format: .localized(.seedCountAccessibilityLabel), seedCount)
    }

    public var body: some View {
        HStack(spacing: spacing) {
            Image("seed", bundle: .ecosia)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(enableAnimation ? bounceScale : 1.0)
                .accessibilityHidden(true)

            Text(displayedSeedCount)
                .font(.headline)
                .foregroundColor(theme.textColor)
                .animatedText(numericValue: seedCount, reduceMotionEnabled: !enableAnimation)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("seed_count_view")
        .onChange(of: seedCount) { _ in
            if enableAnimation {
                triggerBounce()
            }
        }
        .ecosiaThemed(windowUUID, $theme)
    }

    private func triggerBounce() {
        withAnimation(.easeOut(duration: UX.bounceAnimationDuration)) {
            bounceScale = UX.bounceScaleMin
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.bounceAnimationDuration) {
            withAnimation(.spring(response: UX.springResponse, dampingFraction: UX.springDamping, blendDuration: 0)) {
                bounceScale = 1.0
            }
        }
    }
}

// MARK: - Theme
struct EcosiaSeedViewTheme: EcosiaThemeable {
    var textColor = Color.primary

    mutating func applyTheme(theme: Theme) {
        textColor = Color(theme.colors.ecosia.textPrimary)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaSeedView_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaSeedViewInteractivePreview()
    }
}

@available(iOS 16.0, *)
private struct EcosiaSeedViewInteractivePreview: View {
    @State private var seedCount = 42

    var body: some View {
        VStack(spacing: .ecosia.space._l) {
            Text("Interactive Seed Animation Test")
                .font(.title2.bold())

            EcosiaSeedView(seedCount: seedCount, windowUUID: .XCTestDefaultUUID)

            HStack {
                Button("Add Seeds") {
                    seedCount += Int.random(in: 1...5)
                }
                .buttonStyle(.bordered)

                Button("Add 100") {
                    seedCount += 100
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    seedCount = 42
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Text("Static Examples")
                .font(.title3.bold())

            VStack(spacing: .ecosia.space._l) {
                EcosiaSeedView(
                    seedCount: 999,
                    iconSize: .ecosia.space._2l,
                    spacing: .ecosia.space._s,
                    windowUUID: .XCTestDefaultUUID
                )
                EcosiaSeedView(
                    seedCount: 1000,
                    windowUUID: .XCTestDefaultUUID
                )
                EcosiaSeedView(
                    seedCount: 5432,
                    windowUUID: .XCTestDefaultUUID
                )
                EcosiaSeedView(
                    seedCount: 5,
                    enableAnimation: false,
                    windowUUID: .XCTestDefaultUUID
                )
            }
        }
        .padding()
    }
}
#endif
