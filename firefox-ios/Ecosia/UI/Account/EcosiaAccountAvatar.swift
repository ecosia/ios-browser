// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A reusable account avatar component that displays user avatars with progress ring and sparkle animations
@available(iOS 16.0, *)
public struct EcosiaAccountAvatar: View {
    private let avatarURL: URL?
    private let progress: Double
    private let showSparkles: Bool
    private let size: CGFloat
    private let windowUUID: WindowUUID
    
    public init(
        avatarURL: URL?,
        progress: Double,
        showSparkles: Bool = false,
        size: CGFloat = .ecosia.space._6l,
        windowUUID: WindowUUID
    ) {
        self.avatarURL = avatarURL
        self.progress = max(0.0, min(1.0, progress)) // Clamp between 0.0 and 1.0
        self.showSparkles = showSparkles
        self.size = size
        self.windowUUID = windowUUID
    }
    
    public var body: some View {
        ZStack {
            // Progress ring (outermost layer)
            EcosiaAccountProgressBar(
                progress: progress,
                size: progressRingSize,
                strokeWidth: strokeWidth,
                windowUUID: windowUUID
            )
            
            // Avatar (center)
            EcosiaAvatar(
                avatarURL: avatarURL,
                size: avatarSize
            )
            
            // Sparkle animation (overlay)
            if showSparkles {
                EcosiaSparkleAnimation(
                    isVisible: showSparkles,
                    containerSize: sparkleContainerSize,
                    sparkleSize: sparkleSize
                )
            }
        }
        .frame(width: progressRingSize, height: progressRingSize)
    }
    
    // MARK: - Computed Properties
    
    private var strokeWidth: CGFloat {
        // Scale stroke width based on size
        size * 0.06 // 6% of size
    }
    
    private var avatarSize: CGFloat {
        // Avatar size with spacing from progress ring
        size - (strokeWidth * 2) - (.ecosia.space._1s * 2)
    }
    
    private var progressRingSize: CGFloat {
        size
    }
    
    private var sparkleContainerSize: CGFloat {
        // Sparkles appear outside the progress ring
        size + .ecosia.space._s
    }
    
    private var sparkleSize: CGFloat {
        // Scale sparkle size based on avatar size
        size * 0.2
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAccountAvatar_Previews: PreviewProvider {
    static var previews: some View {
        let windowUUID = WindowUUID()
        
        VStack(spacing: .ecosia.space._2l) {
            // With avatar URL and progress
            EcosiaAccountAvatar(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                progress: 0.75,
                windowUUID: windowUUID
            )
            
            // Without avatar URL (placeholder) and with sparkles
            EcosiaAccountAvatar(
                avatarURL: nil,
                progress: 0.25,
                showSparkles: true,
                windowUUID: windowUUID
            )
            
            // Different sizes
            HStack(spacing: .ecosia.space._l) {
                EcosiaAccountAvatar(
                    avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                    progress: 0.5,
                    size: .ecosia.space._4l,
                    windowUUID: windowUUID
                )
                
                EcosiaAccountAvatar(
                    avatarURL: nil,
                    progress: 1.0,
                    size: .ecosia.space._8l,
                    windowUUID: windowUUID
                )
            }
            
            // With sparkles
            EcosiaAccountAvatar(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                progress: 0.9,
                showSparkles: true,
                windowUUID: windowUUID
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
