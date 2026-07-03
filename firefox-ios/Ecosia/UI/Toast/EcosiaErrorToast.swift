// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI error toast wrapper that animates an EcosiaErrorView for temporary display
@available(iOS 16.0, *)
public struct EcosiaErrorToast: View {
    private let subtitle: String
    private let windowUUID: WindowUUID
    private let animatesEntrance: Bool
    private let announcesOnAppear: Bool
    private let onDismiss: () -> Void

    @State private var hasEntered = false
    @State private var opacity: Double = 0

    private struct UX {
        static let toastMinHeight: CGFloat = 56
        static let entranceDuration: TimeInterval = 0.35
        static let fadeDuration: TimeInterval = 0.25
        static let displayDuration: TimeInterval = 4.5
        static let hiddenTopOffset: CGFloat = 120
    }

    public init(
        subtitle: String,
        windowUUID: WindowUUID,
        animatesEntrance: Bool = true,
        announcesOnAppear: Bool = true,
        onDismiss: @escaping () -> Void
    ) {
        self.subtitle = subtitle
        self.windowUUID = windowUUID
        self.animatesEntrance = animatesEntrance
        self.announcesOnAppear = announcesOnAppear
        self.onDismiss = onDismiss

        if animatesEntrance {
            _hasEntered = State(initialValue: false)
            _opacity = State(initialValue: 0)
        } else {
            _hasEntered = State(initialValue: true)
            _opacity = State(initialValue: 1)
        }
    }

    public var body: some View {
        EcosiaErrorView(
            subtitle: subtitle,
            windowUUID: windowUUID,
            onCloseTapped: {
                hide()
            }
        )
        .frame(minHeight: UX.toastMinHeight)
        .padding(.horizontal, .ecosia.space._m)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .offset(y: hasEntered ? 0 : -UX.hiddenTopOffset)
        .opacity(opacity)
        .allowsHitTesting(opacity > 0)
        .onAppear {
            guard animatesEntrance else {
                scheduleAutoDismissAndAnnouncement()
                return
            }

            withAnimation(.spring(response: UX.entranceDuration, dampingFraction: 0.86)) {
                hasEntered = true
                opacity = 1
            }

            scheduleAutoDismissAndAnnouncement()
        }
    }

    private func scheduleAutoDismissAndAnnouncement() {
        let entranceDelay = animatesEntrance ? UX.entranceDuration : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + entranceDelay) {
            guard announcesOnAppear else { return }
            Task { @MainActor in
                guard opacity > 0, hasEntered else { return }
                UIAccessibility.post(notification: .announcement, argument: subtitle)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.displayDuration) {
            hide()
        }
    }

    private func hide() {
        guard opacity > 0 else { return }

        withAnimation(.easeOut(duration: UX.fadeDuration)) {
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.fadeDuration) {
            onDismiss()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorToast_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EcosiaErrorToast(
                subtitle: "Something went wrong. Please sign in again.",
                windowUUID: .XCTestDefaultUUID,
                onDismiss: {}
            )
            Spacer()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
