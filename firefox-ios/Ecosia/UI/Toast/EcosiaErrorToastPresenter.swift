// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@available(iOS 16.0, *)
@MainActor
public protocol EcosiaErrorToastPresenting: AnyObject {
    func presentEcosiaErrorToasts(_ messages: [EcosiaErrorToastMessage])
}

/// Routes Ecosia error notifications to the active browser's top toast stack.
@available(iOS 16.0, *)
@MainActor
public final class EcosiaErrorToastPresenter {
    public static let shared = EcosiaErrorToastPresenter()

    public weak var delegate: EcosiaErrorToastPresenting? {
        didSet {
            flushPendingMessagesIfNeeded()
        }
    }

    private var pendingMessages: [EcosiaErrorToastMessage] = []

    private init() {}

    public func present(subtitle: String, title: String? = nil) {
        present(messages: [EcosiaErrorToastMessage(title: title, subtitle: subtitle)])
    }

    public func present(messages: [EcosiaErrorToastMessage]) {
        guard !messages.isEmpty else { return }

        if let delegate {
            delegate.presentEcosiaErrorToasts(messages)
        } else {
            pendingMessages.append(contentsOf: messages)
        }
    }

    public func presentAuthFlowError(isLogin: Bool) {
        let subtitle = isLogin
            ? String.localized(.signInErrorMessage)
            : String.localized(.signOutErrorMessage)
        present(subtitle: subtitle)
    }

    public func presentRegisterVisitError() {
        present(
            subtitle: String.localized(.couldNotLoadSeedCounterMessage),
            title: String.localized(.couldNotLoadSeedCounter)
        )
    }

    private func flushPendingMessagesIfNeeded() {
        guard let delegate, !pendingMessages.isEmpty else { return }
        let messages = pendingMessages
        pendingMessages.removeAll()
        delegate.presentEcosiaErrorToasts(messages)
    }
}
