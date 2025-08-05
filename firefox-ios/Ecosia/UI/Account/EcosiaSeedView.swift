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

            seedCountText
        }
        .onChange(of: seedCount) { _ in
            if enableAnimation {
                triggerBounce()
            }
        }
    }
    
    private var seedCountText: some View {
        Group {
            if #available(iOS 17.0, *) {
                Text("\(seedCount)")
                    .contentTransition(.numericText(value: Double(seedCount)))
            } else {
                Text("\(seedCount)")
            }
        }
        .font(.headline) // Back to original font size
        .foregroundColor(textColor)
    }
    
    private func triggerBounce() {
        // Prominent squeeze down (compress/absorb feeling)
        withAnimation(.easeOut(duration: 0.2)) {
            bounceScale = 0.75  // 25% smaller - more prominent compression
        }
        
        // Gentle elastic bounce back to normal after longer compression
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                bounceScale = 1.0  // Back to normal size
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaSeedView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            EcosiaSeedView(seedCount: 42)
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
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
