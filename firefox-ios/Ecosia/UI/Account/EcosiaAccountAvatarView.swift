// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Example usage view demonstrating EcosiaAccountAvatar with ViewModel
@available(iOS 16.0, *)
public struct EcosiaAccountAvatarView: View {
    @StateObject private var viewModel: EcosiaAccountAvatarViewModel
    private let windowUUID: WindowUUID
    private let size: CGFloat
    
    public init(
        avatarURL: URL? = nil,
        progress: Double = 0.25,
        size: CGFloat = .ecosia.space._6l,
        windowUUID: WindowUUID
    ) {
        self._viewModel = StateObject(wrappedValue: EcosiaAccountAvatarViewModel(
            avatarURL: avatarURL,
            progress: progress
        ))
        self.size = size
        self.windowUUID = windowUUID
    }
    
    public var body: some View {
        EcosiaAccountAvatar(
            avatarURL: viewModel.avatarURL,
            progress: viewModel.progress,
            showSparkles: viewModel.showSparkles,
            size: size,
            windowUUID: windowUUID
        )
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAccountAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        let windowUUID = WindowUUID()
        
        VStack(spacing: .ecosia.space._2l) {
            // Default state (signed out)
            EcosiaAccountAvatarView(
                windowUUID: windowUUID
            )
            .previewDisplayName("Signed Out (25%)")
            
            // Signed in with avatar
            EcosiaAccountAvatarView(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                progress: 0.75,
                windowUUID: windowUUID
            )
            .previewDisplayName("Signed In (75%)")
            
            // Different sizes
            HStack(spacing: .ecosia.space._l) {
                EcosiaAccountAvatarView(
                    progress: 0.5,
                    size: .ecosia.space._4l,
                    windowUUID: windowUUID
                )
                
                EcosiaAccountAvatarView(
                    progress: 1.0,
                    size: .ecosia.space._8l,
                    windowUUID: windowUUID
                )
            }
            .previewDisplayName("Different Sizes")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Usage Examples
@available(iOS 16.0, *)
struct EcosiaAccountAvatarUsageExamples: View {
    let windowUUID = WindowUUID()
    
    var body: some View {
        VStack(spacing: .ecosia.space._2l) {
            // Example 1: Simple usage
            EcosiaAccountAvatarView(windowUUID: windowUUID)
            
            // Example 2: With data
            EcosiaAccountAvatarView(
                avatarURL: URL(string: "https://example.com/avatar.jpg"),
                progress: 0.6,
                windowUUID: windowUUID
            )
            
            // Example 3: Manual control
            ManualControlExample()
        }
    }
}

@available(iOS 16.0, *)
private struct ManualControlExample: View {
    @StateObject private var viewModel = EcosiaAccountAvatarViewModel(
        progress: 0.3
    )
    let windowUUID = WindowUUID()
    
    var body: some View {
        VStack {
            EcosiaAccountAvatar(
                avatarURL: viewModel.avatarURL,
                progress: viewModel.progress,
                showSparkles: viewModel.showSparkles,
                windowUUID: windowUUID
            )
            
            HStack {
                Button("Add Progress") {
                    let newProgress = min(1.0, viewModel.progress + 0.1)
                    viewModel.updateProgress(newProgress)
                }
                
                Button("Level Up!") {
                    viewModel.triggerSparkles()
                }
                
                Button("Reset") {
                    viewModel.updateProgress(0.25)
                }
            }
        }
    }
}
#endif
