// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A sparkle animation component that displays animated sparkles around content
@available(iOS 16.0, *)
public struct EcosiaSparkleAnimation: View {
    private let isVisible: Bool
    private let containerSize: CGFloat
    private let sparkleSize: CGFloat
    private let animationDuration: Double

    @State private var sparkles: [SparkleData] = []
    @State private var animationOffset: CGFloat = 0
    @State private var opacity: Double = 0

    public init(
        isVisible: Bool,
        containerSize: CGFloat = .ecosia.space._6l,
        sparkleSize: CGFloat = .ecosia.space._1l,
        animationDuration: Double = 2.0
    ) {
        self.isVisible = isVisible
        self.containerSize = containerSize
        self.sparkleSize = sparkleSize
        self.animationDuration = animationDuration
    }

    public var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image("highlight-star", bundle: .ecosia)
                    .resizable()
                    .frame(width: sparkleSize, height: sparkleSize)
                    .offset(x: sparkle.position.x, y: sparkle.position.y)
                    .scaleEffect(sparkle.scale)
                    .opacity(sparkle.opacity)
                    .rotationEffect(.degrees(sparkle.rotation))
            }
        }
        .frame(width: containerSize, height: containerSize)
        .opacity(opacity)
        .onAppear {
            if isVisible {
                startSparkleAnimation()
            }
        }
        .onChange(of: isVisible) { visible in
            if visible {
                startSparkleAnimation()
            } else {
                stopSparkleAnimation()
            }
        }
    }

    private func startSparkleAnimation() {
        generateSparkles()

        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 1.0
        }

        animateSparkles()

        // Auto-hide after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            stopSparkleAnimation()
        }
    }

    private func stopSparkleAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sparkles.removeAll()
        }
    }

    private func generateSparkles() {
        sparkles.removeAll()
        let numberOfSparkles = 6
        let radius = containerSize / 2 + sparkleSize / 2

        for i in 0..<numberOfSparkles {
            let angle = (Double(i) / Double(numberOfSparkles)) * 2 * .pi
            let x = cos(angle) * Double(radius)
            let y = sin(angle) * Double(radius)

            let sparkle = SparkleData(
                position: CGPoint(x: x, y: y),
                scale: Double.random(in: 0.5...1.0),
                opacity: Double.random(in: 0.7...1.0),
                rotation: Double.random(in: 0...360)
            )
            sparkles.append(sparkle)
        }
    }

    private func animateSparkles() {
        for i in sparkles.indices {
            let delay = Double(i) * 0.1

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(
                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
                    .repeatCount(3, autoreverses: true)
                ) {
                    sparkles[i].scale *= 1.2
                    sparkles[i].opacity *= 0.8
                }

                withAnimation(
                    .linear(duration: animationDuration - delay)
                ) {
                    sparkles[i].rotation += 180
                }
            }
        }
    }
}

// MARK: - Supporting Types
private struct SparkleData: Identifiable {
    let id = UUID()
    let position: CGPoint
    var scale: Double
    var opacity: Double
    var rotation: Double
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
