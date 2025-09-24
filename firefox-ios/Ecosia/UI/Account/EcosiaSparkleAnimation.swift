// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A sparkle animation component that displays animated sparkles around content
/// Based on TwinkleView approach with TimelineView for smooth continuous animation
@available(iOS 16.0, *)
public struct EcosiaSparkleAnimation: View {
    private let isVisible: Bool
    private let containerSize: CGFloat
    private let sparkleSize: CGFloat
    private let animationDuration: Double

    @StateObject private var sparkleManager = SparkleManager()

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
        if isVisible {
            GeometryReader { geometry in
                ZStack {
                    TimelineView(.animation) { context in
                        let _ = sparkleManager.update(date: context.date, duration: animationDuration)
                        ForEach(sparkleManager.sparkles) { sparkle in
                            Image("highlight-star", bundle: .ecosia)
                                .resizable()
                                .frame(width: sparkleSize, height: sparkleSize)
                                .scaleEffect(scaleFor(date: context.date, sparkle: sparkle))
                                .position(position(in: geometry, sparkle: sparkle))
                                .opacity(opacityFor(date: context.date, sparkle: sparkle))
                                .rotationEffect(.degrees(rotationFor(date: context.date, sparkle: sparkle)))
                        }
                    }
                }
            }
            .frame(width: containerSize, height: containerSize)
            .onAppear {
                sparkleManager.start(duration: animationDuration)
            }
        } else {
            EmptyView()
        }
    }
    
    private func position(in proxy: GeometryProxy, sparkle: SparkleData) -> CGPoint {
        let radius = min(proxy.size.width, proxy.size.height) / 2.0
        let drawnRadius = (radius - sparkleSize / 2) * sparkle.radiusMultiplier
        let angle = sparkle.angle
        
        let x = proxy.size.width * 0.5 + drawnRadius * cos(angle)
        let y = proxy.size.height * 0.5 + drawnRadius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
    
    private func scaleFor(date: Date, sparkle: SparkleData) -> CGFloat {
        var offset = date.timeIntervalSince(sparkle.startDate)
        offset = max(offset, 0)
        offset = min(offset, animationDuration)
        let halfDuration = animationDuration * 0.5
        
        let baseScale: CGFloat
        if offset < halfDuration {
            baseScale = offset / halfDuration
        } else {
            baseScale = 1.0 - ((offset - halfDuration) / halfDuration)
        }
        
        // Apply sparkle-specific scale multiplier
        return max(0.1, baseScale * sparkle.scaleMultiplier)
    }
    
    private func opacityFor(date: Date, sparkle: SparkleData) -> Double {
        var offset = date.timeIntervalSince(sparkle.startDate)
        offset = max(offset, 0)
        offset = min(offset, animationDuration)
        let halfDuration = animationDuration * 0.5
        
        let baseOpacity: Double
        if offset < halfDuration {
            baseOpacity = offset / halfDuration
        } else {
            baseOpacity = 1.0 - ((offset - halfDuration) / halfDuration)
        }
        
        return max(0.0, baseOpacity * sparkle.opacityMultiplier)
    }
    
    private func rotationFor(date: Date, sparkle: SparkleData) -> Double {
        let offset = date.timeIntervalSince(sparkle.startDate)
        let progress = offset / animationDuration
        return sparkle.initialRotation + (progress * sparkle.rotationSpeed)
    }
}

// MARK: - Supporting Types
private struct SparkleData: Identifiable {
    let id = UUID()
    let angle: Double
    let radiusMultiplier: CGFloat
    let startDate: Date
    let scaleMultiplier: CGFloat
    let opacityMultiplier: Double
    let initialRotation: Double
    let rotationSpeed: Double
}

private class SparkleManager: ObservableObject {
    @Published var sparkles: [SparkleData] = []
    
    func start(duration: Double) {
        let anchor = Date()
        var result: [SparkleData] = []
        
        // Create 8-12 sparkles with random properties
        let numberOfSparkles = Int.random(in: 8...12)
        for _ in 0..<numberOfSparkles {
            result.append(SparkleData(
                angle: Double.random(in: 0...(2 * .pi)),
                radiusMultiplier: CGFloat.random(in: 0.8...1.2),
                startDate: anchor.addingTimeInterval(Double.random(in: 0...duration)),
                scaleMultiplier: CGFloat.random(in: 0.6...1.4),
                opacityMultiplier: Double.random(in: 0.7...1.0),
                initialRotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 180...720) // 0.5 to 2 full rotations
            ))
        }
        self.sparkles = result
    }
    
    func update(date: Date, duration: Double) {
        let anchor = Date()
        var result: [SparkleData] = []
        
        for sparkle in sparkles {
            if anchor.timeIntervalSince(sparkle.startDate) > duration {
                // Replace expired sparkle with a new one
                result.append(SparkleData(
                    angle: Double.random(in: 0...(2 * .pi)),
                    radiusMultiplier: CGFloat.random(in: 0.8...1.2),
                    startDate: anchor.addingTimeInterval(Double.random(in: 0...duration)),
                    scaleMultiplier: CGFloat.random(in: 0.6...1.4),
                    opacityMultiplier: Double.random(in: 0.7...1.0),
                    initialRotation: Double.random(in: 0...360),
                    rotationSpeed: Double.random(in: 180...720)
                ))
            } else {
                result.append(sparkle)
            }
        }
        self.sparkles = result
    }
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
