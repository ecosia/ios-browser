// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

@available(iOS 16.0, *)
public struct EcosiaSparkleAnimation: View {
    private let isVisible: Bool
    private let containerSize: CGFloat
    private let sparkleSize: CGFloat
    private let animationDuration: Double
    private let onComplete: (() -> Void)?

    @State private var sparkles: [SparkleData] = []

    private struct UX {
        static let numberOfSparkles = 6
        static let minSparkleSize: CGFloat = 10
        static let maxSparkleSize: CGFloat = 24
        static let radiusMultiplierMin: CGFloat = 0.4
        static let radiusMultiplierMax: CGFloat = 1.2
        static let animationDelayMax = 1.0
        static let sparkleLifetimeMin = 1.0
        static let sparkleLifetimeMax = 2.0
        static let opacityMin = 0.8
        static let opacityMax = 1.0
        static let fadeOutDuration = 0.4
    }

    public init(
        isVisible: Bool,
        containerSize: CGFloat = .ecosia.space._6l,
        sparkleSize: CGFloat = 24,
        animationDuration: Double = 6.0,
        onComplete: (() -> Void)? = nil
    ) {
        self.isVisible = isVisible
        self.containerSize = containerSize
        self.sparkleSize = sparkleSize
        self.animationDuration = animationDuration
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            if isVisible {
                ForEach(sparkles) { sparkle in
                    Image("highlight-star", bundle: .ecosia)
                        .resizable()
                        .frame(width: sparkle.size, height: sparkle.size)
                        .position(sparkle.position)
                        .opacity(sparkle.opacity)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(width: containerSize, height: containerSize)
        .onChange(of: isVisible) { visible in
            if visible {
                startSparkleAnimation()
            } else {
                stopSparkleAnimation()
            }
        }
        .onAppear {
            if isVisible {
                startSparkleAnimation()
            }
        }
    }

    private func startSparkleAnimation() {
        generateSparkles()
        animateSparkles()

        // Run for animationDuration, then gracefully fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            stopSparkleAnimation()
        }
    }

    private func stopSparkleAnimation() {
        withAnimation(.easeOut(duration: UX.fadeOutDuration)) {
            for i in sparkles.indices {
                sparkles[i].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.fadeOutDuration) {
            sparkles.removeAll()
            onComplete?()
        }
    }

    private func generateSparkles() {
        sparkles.removeAll()

        for _ in 0..<UX.numberOfSparkles {
            let radius = min(containerSize, containerSize) / 2.0
            let radiusMultiplier = CGFloat.random(in: UX.radiusMultiplierMin...UX.radiusMultiplierMax)
            let drawnRadius = (radius - sparkleSize / 2) * radiusMultiplier
            let angle = Double.random(in: 0...(2 * .pi))

            let x = containerSize * 0.5 + drawnRadius * cos(angle)
            let y = containerSize * 0.5 + drawnRadius * sin(angle)

            let sparkle = SparkleData(
                position: CGPoint(x: x, y: y),
                size: CGFloat.random(in: UX.minSparkleSize...UX.maxSparkleSize),
                opacity: 0.0
            )
            sparkles.append(sparkle)
        }
    }

    private func animateSparkles() {
        for i in sparkles.indices {
            let delay = Double.random(in: 0...UX.animationDelayMax)
            let sparkleLifetime = Double.random(in: UX.sparkleLifetimeMin...UX.sparkleLifetimeMax)
            let finalOpacity = Double.random(in: UX.opacityMin...UX.opacityMax)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let halfLifetime = sparkleLifetime / 2.0

                withAnimation(.easeIn(duration: halfLifetime)) {
                    sparkles[i].opacity = finalOpacity
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + halfLifetime) {
                    withAnimation(.easeOut(duration: halfLifetime)) {
                        sparkles[i].opacity = 0
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types
private struct SparkleData: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    var opacity: Double
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaSparkleAnimation_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._2l) {
            // Sparkles visible
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: .ecosia.space._6l, height: .ecosia.space._6l)

                EcosiaSparkleAnimation(isVisible: true)
            }

            // Different sizes
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: .ecosia.space._8l, height: .ecosia.space._8l)

                EcosiaSparkleAnimation(
                    isVisible: true,
                    containerSize: .ecosia.space._8l,
                    sparkleSize: .ecosia.space._1l
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
