// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Interactive test view for manually testing EcosiaAccountAvatar functionality
@available(iOS 16.0, *)
struct EcosiaAccountAvatarTestView: View {
    @StateObject private var viewModel = EcosiaAccountAvatarViewModel(progress: 0.3)
    let windowUUID = WindowUUID()

    var body: some View {
        ScrollView {
            VStack(spacing: .ecosia.space._2l) {

                // MARK: - Interactive Testing
                Text("Interactive Testing")
                    .font(.title2.bold())

                EcosiaAccountAvatar(
                    avatarURL: viewModel.avatarURL,
                    progress: viewModel.progress,
                    showSparkles: viewModel.showSparkles,
                    size: .ecosia.space._8l,
                    windowUUID: windowUUID
                )

                Text("Progress: \(Int(viewModel.progress * 100))%")
                    .font(.caption)

                // Control buttons
                VStack(spacing: .ecosia.space._s) {
                    HStack {
                        Button("Add Progress") {
                            let newProgress = min(1.0, viewModel.progress + 0.1)
                            viewModel.updateProgress(newProgress)
                        }
                        .buttonStyle(.bordered)

                        Button("Level Up!") {
                            viewModel.updateProgress(min(1.0, viewModel.progress + 0.2))
                            viewModel.triggerSparkles()
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
                }

                Divider()

                // MARK: - Notification Testing
                Text("Notification Testing")
                    .font(.title2.bold())

                VStack(spacing: .ecosia.space._s) {
                    Button("Send Progress Notification (60%)") {
                        EcosiaAccountNotificationCenter.postProgressUpdated(progress: 0.6, level: 2)
                    }
                    .buttonStyle(.bordered)

                    Button("Send Level Up Notification (80%)") {
                        EcosiaAccountNotificationCenter.postLevelUp(newLevel: 3, newProgress: 0.8)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Divider()

                // MARK: - State Variations
                Text("State Variations")
                    .font(.title2.bold())

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .ecosia.space._l) {

                    VStack {
                        Text("Signed Out (25%)")
                            .font(.caption)
                        EcosiaAccountAvatar(
                            avatarURL: nil,
                            progress: 0.25,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Signed In (75%)")
                            .font(.caption)
                        EcosiaAccountAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.75,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("With Sparkles")
                            .font(.caption)
                        EcosiaAccountAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.9,
                            showSparkles: true,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Complete (100%)")
                            .font(.caption)
                        EcosiaAccountAvatar(
                            avatarURL: nil,
                            progress: 1.0,
                            windowUUID: windowUUID
                        )
                    }
                }

                Divider()

                // MARK: - Size Variations
                Text("Size Variations")
                    .font(.title2.bold())

                HStack(spacing: .ecosia.space._l) {
                    VStack {
                        Text("Small")
                            .font(.caption)
                        EcosiaAccountAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.6,
                            size: .ecosia.space._4l,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Medium")
                            .font(.caption)
                        EcosiaAccountAvatar(
                            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                            progress: 0.6,
                            size: .ecosia.space._6l,
                            windowUUID: windowUUID
                        )
                    }

                    VStack {
                        Text("Large")
                            .font(.caption)
                        EcosiaAccountAvatar(
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
        .navigationTitle("EcosiaAccountAvatar Test")
    }
}

#if DEBUG
// MARK: - Previews following Apple's best practices
@available(iOS 16.0, *)
#Preview("Interactive Test View") {
    NavigationView {
        EcosiaAccountAvatarTestView()
    }
}

// MARK: - Simple Component Previews (following Apple's "pass only data needed" principle)
@available(iOS 17.0, *)
#Preview("All Avatar States", traits: .sizeThatFitsLayout) {
    let windowUUID = WindowUUID()

    VStack(spacing: 20) {
        // Pass only the data each view needs
        EcosiaAccountAvatar(
            avatarURL: nil,
            progress: 0.25,
            windowUUID: windowUUID
        )
        .previewDisplayName("Signed Out (25%)")

        EcosiaAccountAvatar(
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
            progress: 0.75,
            windowUUID: windowUUID
        )
        .previewDisplayName("Signed In (75%)")

        EcosiaAccountAvatar(
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
            progress: 0.9,
            showSparkles: true,
            windowUUID: windowUUID
        )
        .previewDisplayName("With Sparkles")

        EcosiaAccountAvatar(
            avatarURL: nil,
            progress: 1.0,
            windowUUID: windowUUID
        )
        .previewDisplayName("Complete (100%)")
    }
    .padding()
}

@available(iOS 17.0, *)
#Preview("Size Variations", traits: .sizeThatFitsLayout) {
    let windowUUID = WindowUUID()

    HStack(spacing: 20) {
        EcosiaAccountAvatar(
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
            progress: 0.6,
            size: .ecosia.space._4l,
            windowUUID: windowUUID
        )

        EcosiaAccountAvatar(
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
            progress: 0.6,
            size: .ecosia.space._6l,
            windowUUID: windowUUID
        )

        EcosiaAccountAvatar(
            avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
            progress: 0.6,
            size: .ecosia.space._8l,
            windowUUID: windowUUID
        )
    }
    .padding()
}
#endif
