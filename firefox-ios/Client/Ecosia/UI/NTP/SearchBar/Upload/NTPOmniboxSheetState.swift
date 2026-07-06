// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import Ecosia

@MainActor
final class NTPOmniboxSheetState: ObservableObject {
    @Published var showUploadDrawer = false
    @Published var showSignInSheet = false

    private enum PendingAuthAction {
        case signIn
        case signUp
    }

    private var onUploadOptionSelected: ((OmniboxUploadOption) -> Void)?
    private var pendingUploadOption: OmniboxUploadOption?

    private var pendingAuthAction: PendingAuthAction?
    private var shouldPresentUploadDrawerAfterAuth = false
    private var onSignIn: (() -> Void)?
    private var onSignUp: (() -> Void)?
    private var onUploadDrawerRequested: (() -> Void)?

    func presentSignInSheetForUpload(
        onSignIn: @escaping () -> Void,
        onSignUp: @escaping () -> Void,
        onUploadDrawerRequested: @escaping () -> Void
    ) {
        pendingAuthAction = nil
        shouldPresentUploadDrawerAfterAuth = true
        self.onSignIn = onSignIn
        self.onSignUp = onSignUp
        self.onUploadDrawerRequested = onUploadDrawerRequested
        showSignInSheet = true
    }

    func handleSignInSheetSignInTapped() {
        pendingAuthAction = .signIn
        showSignInSheet = false
    }

    func handleSignInSheetCreateAccountTapped() {
        pendingAuthAction = .signUp
        showSignInSheet = false
    }

    func handleSignInSheetDismissed() {
        guard let action = pendingAuthAction else {
            clearSignInSheetCallbacks()
            return
        }

        pendingAuthAction = nil
        switch action {
        case .signIn:
            onSignIn?()
        case .signUp:
            onSignUp?()
        }
        onSignIn = nil
        onSignUp = nil
    }

    func handleAuthenticationCompleted(success: Bool) {
        guard shouldPresentUploadDrawerAfterAuth else { return }
        guard success else {
            clearSignInSheetCallbacks()
            return
        }
        shouldPresentUploadDrawerAfterAuth = false
        let callback = onUploadDrawerRequested
        onUploadDrawerRequested = nil
        callback?()
    }

    func handleAuthenticationSucceeded() {
        handleAuthenticationCompleted(success: true)
    }

    private func clearSignInSheetCallbacks() {
        pendingAuthAction = nil
        shouldPresentUploadDrawerAfterAuth = false
        onSignIn = nil
        onSignUp = nil
        onUploadDrawerRequested = nil
    }

    func presentUploadDrawer(onSelect: @escaping (OmniboxUploadOption) -> Void) {
        pendingUploadOption = nil
        onUploadOptionSelected = onSelect
        showUploadDrawer = true
    }

    func handleUploadOptionSelected(_ option: OmniboxUploadOption) {
        pendingUploadOption = option
        showUploadDrawer = false
    }

    func handleUploadDrawerDismissed() {
        guard let option = pendingUploadOption else {
            onUploadOptionSelected = nil
            return
        }
        pendingUploadOption = nil
        let callback = onUploadOptionSelected
        onUploadOptionSelected = nil
        callback?(option)
    }
}
