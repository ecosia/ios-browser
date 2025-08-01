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

            seedCountText
        }
    }
    
    private var seedCountText: some View {
        let duration = 0.3
        let delay = 0.3
        let animation: Animation? = enableAnimation ? .easeInOut(duration: duration).delay(delay) : nil
        
        return Group {
            if #available(iOS 17.0, *) {
                Text("\(seedCount)")
                    .contentTransition(.numericText(value: Double(seedCount)))
            } else {
                Text("\(seedCount)")
            }
        }
        .font(.headline)
        .foregroundColor(textColor)
        .animation(animation, value: seedCount)
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
