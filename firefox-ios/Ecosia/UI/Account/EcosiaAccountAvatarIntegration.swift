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
@available(iOS 16.0, *)
struct QuickTestButton: View {
    @State private var showTestView = false

    var body: some View {
        Button("🧪 Test EcosiaAccountAvatar") {
            showTestView = true
        }
        .sheet(isPresented: $showTestView) {
            NavigationView {
                EcosiaAccountAvatarTestView()
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
