// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit

/// Manager for showing/hiding loading overlays during authentication flows
public class LoadingOverlayManager: ObservableObject {
    public static let shared = LoadingOverlayManager()

    @Published private var isShowingLoading = false
    private var overlayWindow: UIWindow?

    private init() {}

    /// Shows authentication loading overlay on the main window
    @MainActor
    public func showAuthenticationLoadingIfNeeded() {
        guard !isShowingLoading else { return }

        // Find the main window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("❌ LoadingOverlayManager - Could not find window scene")
            return
        }

        showLoadingOverlay(in: windowScene)
    }

    /// Shows loading overlay on the main window
    @MainActor
    public func showLoadingOverlay(in windowScene: UIWindowScene) {
        guard !isShowingLoading else { return }

        isShowingLoading = true
        print("🔄 LoadingOverlayManager - Showing authentication loading overlay on main window")

        // Create a new window for the overlay
        let overlayWindow = UIWindow(windowScene: windowScene)
        overlayWindow.windowLevel = UIWindow.Level.alert + 1 // Above everything
        overlayWindow.backgroundColor = UIColor.clear

        // Create SwiftUI loading view
        let loadingView = AuthenticationLoadingView()
        let hostingController = UIHostingController(rootView: loadingView)
        hostingController.view.backgroundColor = UIColor.clear

        overlayWindow.rootViewController = hostingController
        overlayWindow.makeKeyAndVisible()

        // Store reference to dismiss later
        self.overlayWindow = overlayWindow
    }

    /// Dismisses the loading overlay
    @MainActor
    public func dismissLoading() {
        guard isShowingLoading else { return }

        isShowingLoading = false
        print("🔄 LoadingOverlayManager - Dismissing authentication loading overlay")

        // Hide and remove the overlay window
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
}

/// SwiftUI view for authentication loading state with animated Ecosia trees
struct AuthenticationLoadingView: View {
    @State private var currentTreeIndex = 0
    @State private var bounceScale: CGFloat = 1.0

    private let treeImages = ["smallTree", "splashTree1", "splashTree2"]

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 30) {

                Image(treeImages[currentTreeIndex])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .scaleEffect(bounceScale)
                    .animation(.easeInOut(duration: 0.6), value: bounceScale)
                    .animation(.easeInOut(duration: 0.8), value: currentTreeIndex)

                Text("Completing sign in...")
                    .foregroundColor(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.8))
                    .shadow(radius: 10)
            )
        }
        .onAppear {
            startTreeAnimation()
        }
    }

    private func startTreeAnimation() {
        // Start the bounce animation
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                bounceScale = bounceScale == 1.0 ? 1.2 : 1.0
            }
        }

        // Cycle through tree images
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                currentTreeIndex = (currentTreeIndex + 1) % treeImages.count
            }
        }
    }
}

#if DEBUG
struct AuthenticationLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationLoadingView()
    }
}
#endif
