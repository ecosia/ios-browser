// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A sparkle animation component that displays animated sparkles around content
/// Simplified approach to avoid freezing issues
@available(iOS 16.0, *)
public struct EcosiaSparkleAnimation: View {
    private let isVisible: Bool
    private let containerSize: CGFloat
    private let sparkleSize: CGFloat
    private let animationDuration: Double

    @State private var sparkles: [SparkleData] = []
    @State private var animationTrigger = false

    public init(
        isVisible: Bool,
        containerSize: CGFloat = .ecosia.space._6l,
        sparkleSize: CGFloat = .ecosia.space._2l, // Much larger sparkles
        animationDuration: Double = 2.0
    ) {
        self.isVisible = isVisible
        self.containerSize = containerSize
        self.sparkleSize = sparkleSize
        self.animationDuration = animationDuration
    }

    public var body: some View {
        ZStack {
            if isVisible {
                ForEach(sparkles) { sparkle in
                    Image("highlight-star", bundle: .ecosia)
                        .resizable()
                        .frame(width: sparkleSize, height: sparkleSize)
                        .position(sparkle.position)
                        .scaleEffect(sparkle.scale)
                        .opacity(sparkle.opacity)
                        .rotationEffect(.degrees(sparkle.rotation))
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
    }

    private func stopSparkleAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            for i in sparkles.indices {
                sparkles[i].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sparkles.removeAll()
        }
    }

    private func generateSparkles() {
        sparkles.removeAll()
        let numberOfSparkles = 6 // Like in the image
        
        for _ in 0..<numberOfSparkles {
            // Generate random position using TwinkleView approach
            let radius = min(containerSize, containerSize) / 2.0
            let radiusMultiplier = CGFloat.random(in: 0.4...1.2) // Random distance from center
            let drawnRadius = (radius - sparkleSize / 2) * radiusMultiplier
            let angle = Double.random(in: 0...(2 * .pi)) // Random angle
            
            let x = containerSize * 0.5 + drawnRadius * cos(angle)
            let y = containerSize * 0.5 + drawnRadius * sin(angle)

            let sparkle = SparkleData(
                position: CGPoint(x: x, y: y),
                scale: 0.1,
                opacity: 0.0,
                rotation: Double.random(in: 0...360)
            )
            sparkles.append(sparkle)
        }
    }

    private func animateSparkles() {
        for i in sparkles.indices {
            // Random start time like TwinkleView (some sparkles appear later)
            let delay = Double.random(in: 0...0.8)
            let sparkleLifetime = Double.random(in: 1.2...2.0) // Individual lifetimes
            let finalScale = CGFloat.random(in: 0.8...1.2)
            let finalOpacity = Double.random(in: 0.8...1.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // TwinkleView-style fade in/out cycle
                let halfLifetime = sparkleLifetime / 2.0
                
                // Fade in (first half of lifetime)
                withAnimation(.easeIn(duration: halfLifetime)) {
                    sparkles[i].scale = finalScale
                    sparkles[i].opacity = finalOpacity
                }
                
                // Gentle rotation throughout lifetime
                withAnimation(.linear(duration: sparkleLifetime)) {
                    sparkles[i].rotation += Double.random(in: 90...270)
                }
                
                // Fade out (second half of lifetime)
                DispatchQueue.main.asyncAfter(deadline: .now() + halfLifetime) {
                    withAnimation(.easeOut(duration: halfLifetime)) {
                        sparkles[i].opacity = 0
                        sparkles[i].scale *= 0.3
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
    var scale: CGFloat
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
