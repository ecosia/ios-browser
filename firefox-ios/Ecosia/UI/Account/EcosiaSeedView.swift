// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A reusable seed count component that displays the seed icon and animated count
@available(iOS 16.0, *)
public struct EcosiaSeedView: View {
    private let seedCount: Int
    private let iconSize: CGFloat
    private let textColor: Color
    private let spacing: CGFloat
    private let enableAnimation: Bool
    @State private var bounceScale: CGFloat = 1.0

    private struct UX {
        static let bounceScaleMin: CGFloat = 0.75
        static let bounceAnimationDuration: TimeInterval = 0.3
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.45
    }

    public init(
        seedCount: Int,
        iconSize: CGFloat = .ecosia.space._1l,
        textColor: Color = .primary,
        spacing: CGFloat = .ecosia.space._1s,
        enableAnimation: Bool = true
    ) {
        self.seedCount = seedCount
        self.iconSize = iconSize
        self.textColor = textColor
        self.spacing = spacing
        self.enableAnimation = enableAnimation
    }

    public var body: some View {
        HStack(spacing: spacing) {
            Image("seed", bundle: .ecosia)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .scaleEffect(enableAnimation ? bounceScale : 1.0)
                .accessibilityLabel("Seed icon")

            Text("\(seedCount)")
                .font(.headline)
                .foregroundColor(textColor)
                .animatedText(numericValue: seedCount, reduceMotionEnabled: !enableAnimation)
        }
        .onChange(of: seedCount) { _ in
            if enableAnimation {
                triggerBounce()
            }
        }
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

            EcosiaSeedView(seedCount: seedCount)

            HStack {
                Button("Add Seeds") {
                    seedCount += Int.random(in: 1...5)
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
                    seedCount: 100,
                    iconSize: .ecosia.space._2l,
                    spacing: .ecosia.space._s
                )
                EcosiaSeedView(
                    seedCount: 5,
                    textColor: .blue
                )
                EcosiaSeedView(
                    seedCount: 1,
                    enableAnimation: false
                )
            }
        }
        .padding()
    }
}
#endif
