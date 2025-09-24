// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Easy integration examples for adding EcosiaAccountAvatar to existing screens
@available(iOS 16.0, *)
public struct EcosiaAccountAvatarIntegration {

    // MARK: - Quick Integration Examples

    /// Add this to any toolbar or header
    public static func toolbarAvatar(windowUUID: WindowUUID) -> some View {
        EcosiaAccountAvatarView(
            progress: 0.6, // Replace with real progress data
            size: .ecosia.space._4l,
            windowUUID: windowUUID
        )
    }

    /// Add this to profile screens
    public static func profileAvatar(user: UserData?, windowUUID: WindowUUID) -> some View {
        EcosiaAccountAvatarView(
            avatarURL: user?.avatarURL,
            progress: user?.levelProgress ?? 0.25,
            windowUUID: windowUUID
        )
    }

    /// Add this to settings or account screens
    public static func settingsAvatar(windowUUID: WindowUUID) -> some View {
        EcosiaAccountAvatarView(
            avatarURL: Auth.shared.userProfile?.pictureURL,
            progress: 0.5, // Replace with real data
            size: .ecosia.space._8l,
            windowUUID: windowUUID
        )
    }
}

// MARK: - Temporary User Data (Replace with real data)
public struct UserData {
    let avatarURL: URL?
    let levelProgress: Double
}

// MARK: - Integration Examples

/// Example: Add to Navigation Bar
@available(iOS 16.0, *)
struct ExampleNavigationIntegration: View {
    let windowUUID = WindowUUID()

    var body: some View {
        NavigationView {
            VStack {
                Text("Your App Content")
                Spacer()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EcosiaAccountAvatarIntegration.toolbarAvatar(windowUUID: windowUUID)
                }
            }
        }
    }
}

/// Example: Add to Profile Screen
@available(iOS 16.0, *)
struct ExampleProfileIntegration: View {
    let windowUUID = WindowUUID()

    var body: some View {
        VStack(spacing: .ecosia.space._2l) {
            // Large avatar at top of profile
            EcosiaAccountAvatarIntegration.settingsAvatar(windowUUID: windowUUID)

            Text("User Name")
                .font(.title2.bold())

            Text("Level 3 Explorer")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

/// Example: Quick Test Button (Add anywhere for testing)
/// Note: Interactive testing is now available directly in EcosiaAccountAvatar SwiftUI previews
@available(iOS 16.0, *)
struct QuickTestButton: View {
    @State private var showTestView = false
    let windowUUID = WindowUUID()

    var body: some View {
        Button("🧪 Test EcosiaAccountAvatar") {
            showTestView = true
        }
        .sheet(isPresented: $showTestView) {
            NavigationView {
                EcosiaAccountAvatarInteractiveDemo()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showTestView = false
                            }
                        }
                    }
            }
        }
    }
}

/// Interactive demo view for testing EcosiaAccountAvatar functionality
@available(iOS 16.0, *)
private struct EcosiaAccountAvatarInteractiveDemo: View {
    @StateObject private var viewModel = EcosiaAccountAvatarViewModel(progress: 0.3)
    let windowUUID = WindowUUID()

    var body: some View {
        ScrollView {
            VStack(spacing: .ecosia.space._2l) {
                Text("EcosiaAccountAvatar Interactive Demo")
                    .font(.title2.bold())

                EcosiaAccountAvatar(
                    avatarURL: viewModel.avatarURL,
                    progress: viewModel.progress,
                    showSparkles: viewModel.showSparkles,
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
                        Button("Test Sparkles") {
                            viewModel.triggerSparkles()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Complete Progress") {
                            viewModel.updateProgress(1.0)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Avatar Test")
    }
}

#if DEBUG
// MARK: - Previews
@available(iOS 16.0, *)
#Preview("Navigation Integration") {
    ExampleNavigationIntegration()
}

@available(iOS 16.0, *)
#Preview("Profile Integration") {
    NavigationView {
        ExampleProfileIntegration()
    }
}

@available(iOS 16.0, *)
#Preview("Quick Test Button") {
    QuickTestButton()
}
#endif
