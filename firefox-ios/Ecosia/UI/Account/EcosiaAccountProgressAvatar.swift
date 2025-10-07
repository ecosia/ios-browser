// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

@available(iOS 16.0, *)
public struct EcosiaAccountProgressAvatar: View {
    private let avatarURL: URL?
    private let progress: Double
    private let showSparkles: Bool
    private let showProgress: Bool
    private let size: CGFloat
    private let windowUUID: WindowUUID

    public init(
        avatarURL: URL?,
        progress: Double,
        showSparkles: Bool = false,
        showProgress: Bool = false,
        size: CGFloat = .ecosia.space._6l,
        windowUUID: WindowUUID
    ) {
        self.avatarURL = avatarURL
        self.progress = max(0.0, min(1.0, progress))
        self.showSparkles = showSparkles && showProgress // Only show sparkles if progress is visible
        self.showProgress = showProgress
        self.size = size
        self.windowUUID = windowUUID
    }

    public var body: some View {
        ZStack {
            // Progress ring (outermost layer) - only shown if showProgress is true
            if showProgress {
                EcosiaAccountProgressBar(
                    progress: progress,
                    size: progressRingSize,
                    strokeWidth: strokeWidth,
                    windowUUID: windowUUID
                )
            }

            EcosiaAvatar(
                avatarURL: avatarURL,
                size: avatarSize
            )

            // Sparkles animation (overlay) - only shown if both showSparkles and showProgress are true
            if showSparkles && showProgress {
                EcosiaSparkleAnimation(
                    isVisible: showSparkles,
                    containerSize: sparkleContainerSize,
                    sparkleSize: sparkleSize
                )
            }
        }
        .frame(width: progressRingSize, height: progressRingSize)
    }

    private struct UX {
        static let strokeWidthRatio: CGFloat = 0.06
        static let sparkleContainerPadding: CGFloat = .ecosia.space._s
        static let sparkleSizeRatio: CGFloat = 0.2
    }

    private var strokeWidth: CGFloat {
        size * UX.strokeWidthRatio
    }

    private var avatarSize: CGFloat {
        size - (strokeWidth * 2)
    }

    private var progressRingSize: CGFloat {
        size
    }

    private var sparkleContainerSize: CGFloat {
        size + UX.sparkleContainerPadding
    }

    private var sparkleSize: CGFloat {
        size * UX.sparkleSizeRatio
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaAccountProgressAvatar_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaAccountProgressAvatarInteractivePreview()
    }
}

@available(iOS 16.0, *)
private struct EcosiaAccountProgressAvatarInteractivePreview: View {
    @StateObject private var viewModel = EcosiaAccountAvatarViewModel(progress: 0.3)
    let windowUUID = WindowUUID()

    var body: some View {
        ScrollView {
            VStack(spacing: .ecosia.space._2l) {
                Text("Interactive Testing")
                    .font(.title2.bold())

                EcosiaAccountProgressAvatar(
                    avatarURL: viewModel.avatarURL,
                    progress: viewModel.progress,
                    showSparkles: viewModel.showSparkles,
                    showProgress: true, // Enable progress in preview
                    size: .ecosia.space._7l,
                    windowUUID: windowUUID
                )

                Text("Progress: \(Int(viewModel.progress * 100))%")
                    .font(.caption)

                VStack(spacing: .ecosia.space._s) {
                    HStack {
                        Button("Add Progress") {
                            let newProgress = min(1.0, viewModel.progress + 0.1)
                            viewModel.updateProgress(newProgress)
                        }
                        .buttonStyle(.bordered)

                        Button("Level Up!") {
                            viewModel.levelUp()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Reset") {
                            viewModel.updateProgress(0.25)
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Button("Add Avatar") {
                            viewModel.updateAvatarURL(URL(string: "https://avatars.githubusercontent.com/u/1?v=4"))
                        }
                        .buttonStyle(.bordered)

                        Button("Remove Avatar") {
                            viewModel.updateAvatarURL(nil)
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack {
                        Button("Test Sparkles") {
                            viewModel.triggerSparkles()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Divider()

                Text("State Variations")
                    .font(.title2.bold())

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .ecosia.space._l) {

                    VStack {
                        Text("Hidden Progress")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: nil,
                            progress: 0.25,
                            showProgress: false,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Signed In (75%)")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.75,
                            showProgress: true,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Complete (100%)")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: nil,
                            progress: 1.0,
                            showProgress: true,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Large Size")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.6,
                            showProgress: true,
                            size: .ecosia.space._8l,
                            windowUUID: windowUUID
                        )
                    }
                }

                Divider()

                Text("Size Variations")
                    .font(.title2.bold())

                HStack(spacing: .ecosia.space._l) {
                    VStack {
                        Text("Small")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.6,
                            size: .ecosia.space._4l,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Medium")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.6,
                            size: .ecosia.space._6l,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Large")
                            .font(.caption)
                        EcosiaAccountProgressAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.6,
                            size: .ecosia.space._8l,
                            windowUUID: windowUUID
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("EcosiaAccountProgressAvatar")
    }
}
#endif
