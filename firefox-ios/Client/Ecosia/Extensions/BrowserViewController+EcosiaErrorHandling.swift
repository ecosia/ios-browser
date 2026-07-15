// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

private enum EcosiaErrorToastContainerUX {
    static let presentationAnimationDuration: TimeInterval = 0.45
    static let displayDuration: TimeInterval = 4.5
}

private struct EcosiaErrorToastAssociatedKeys {
    nonisolated(unsafe) static var container: UInt8 = 0
}

@available(iOS 16.0, *)
private struct EcosiaErrorToastStackHost: View {
    @ObservedObject var model: EcosiaErrorToastStackModel
    let windowUUID: WindowUUID

    var body: some View {
        EcosiaErrorToastStack(
            model: model,
            windowUUID: windowUUID
        )
    }
}

/// Fixed top-aligned host for the overlapping SwiftUI error toast stack.
@available(iOS 16.0, *)
@MainActor
final class EcosiaErrorToastContainerView: UIView {
    private let model = EcosiaErrorToastStackModel()
    private var hostingController: UIHostingController<EcosiaErrorToastStackHost>?
    private var autoDismissWorkItem: DispatchWorkItem?

    private weak var parentViewController: UIViewController?
    private var windowUUID: WindowUUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(parent: UIViewController, windowUUID: WindowUUID) {
        parentViewController = parent
        self.windowUUID = windowUUID
        model.onDismissCompleted = { [weak self] in
            self?.handleMessageDismissed()
        }
        installHostingIfNeeded()
    }

    /// Appends errors in order; the first message sits at the back, the last is on top.
    func present(messages: [EcosiaErrorToastMessage]) {
        guard !messages.isEmpty,
              let parentViewController,
              let windowUUID else { return }

        installHostingIfNeeded()

        let wasEmpty = model.messages.isEmpty
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            model.append(messages: messages)
        }
        scheduleFrontMessageAutoDismiss()

        if let announcement = messages.last?.accessibilityAnnouncement {
            let delay = wasEmpty
                ? EcosiaErrorToastContainerUX.presentationAnimationDuration
                : EcosiaErrorToastContainerUX.presentationAnimationDuration + 0.05
            announceAccessibilityMessage(announcement, after: delay)
        }
    }

    /// Appends subtitle-only errors in order; the first message sits at the back, the last is on top.
    func present(subtitles: [String]) {
        present(messages: subtitles.map { EcosiaErrorToastMessage(subtitle: $0) })
    }

    func clear() {
        cancelAutoDismiss()
        model.clear()
    }

    private func installHostingIfNeeded() {
        guard hostingController == nil,
              let parentViewController,
              let windowUUID else { return }

        let host = EcosiaErrorToastStackHost(model: model, windowUUID: windowUUID)
        let hostingController = UIHostingController(rootView: host)
        hostingController.view.backgroundColor = .clear
        hostingController.sizingOptions = [.intrinsicContentSize]
        self.hostingController = hostingController

        parentViewController.addChild(hostingController)
        addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController.didMove(toParent: parentViewController)
    }

    private func announceAccessibilityMessage(_ message: String, after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self,
                  self.model.messages.last?.accessibilityAnnouncement == message else { return }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    private func scheduleFrontMessageAutoDismiss() {
        cancelAutoDismiss()
        guard let frontID = model.messages.last?.id else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.model.messages.last?.id == frontID else { return }
            self.model.requestDismiss(id: frontID)
        }
        autoDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + EcosiaErrorToastContainerUX.displayDuration,
            execute: workItem
        )
    }

    private func handleMessageDismissed() {
        if model.messages.isEmpty {
            cancelAutoDismiss()
        } else {
            scheduleFrontMessageAutoDismiss()
        }
    }

    private func cancelAutoDismiss() {
        autoDismissWorkItem?.cancel()
        autoDismissWorkItem = nil
    }
}

@available(iOS 16.0, *)
extension BrowserViewController: EcosiaErrorToastPresenting {
    func presentEcosiaErrorToasts(_ messages: [EcosiaErrorToastMessage]) {
        guard !messages.isEmpty else { return }
        let container = ensureEcosiaErrorToastContainer()
        container.present(messages: messages)
    }
}

@available(iOS 16.0, *)
extension BrowserViewController {

    /// Shows one or more top-aligned error notifications in the fixed stack container.
    func showEcosiaErrorToasts(messages: [String]) {
        guard !messages.isEmpty else { return }
        presentEcosiaErrorToasts(messages.map { EcosiaErrorToastMessage(subtitle: $0) })
    }

    /// Shows a single top-aligned error notification.
    func showEcosiaErrorToast(message: String) {
        showEcosiaErrorToasts(messages: [message])
    }

    /// Shows an error toast for auth flow failures
    /// - Parameters:
    ///   - isLogin: Whether this was a login (true) or logout (false) error
    func showAuthFlowErrorToast(isLogin: Bool, errorMessage: String? = nil) {
        #if MOZ_CHANNEL_BETA
        if let errorMessage {
            var subtitle = isLogin
                ? String.localized(.signInErrorMessage)
                : String.localized(.signOutErrorMessage)
            subtitle += "Additional details: \(errorMessage)"
            EcosiaErrorToastPresenter.shared.present(subtitle: subtitle)
            return
        }
        #endif

        EcosiaErrorToastPresenter.shared.presentAuthFlowError(isLogin: isLogin)
    }

    @discardableResult
    private func ensureEcosiaErrorToastContainer() -> EcosiaErrorToastContainerView {
        EcosiaErrorToastPresenter.shared.delegate = self
        if let container = activeErrorToastContainer {
            if container.superview === view {
                view.bringSubviewToFront(container)
                return container
            }
            container.clear()
            container.removeFromSuperview()
            activeErrorToastContainer = nil
        }

        let container = EcosiaErrorToastContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.configure(parent: self, windowUUID: windowUUID)
        view.addSubview(container)
        view.bringSubviewToFront(container)

        var constraints: [NSLayoutConstraint] = []

        if let homepage = contentContainer.contentController as? HomepageViewController,
           let searchBar = homepage.ntpSearchBar,
           searchBar.window != nil {
            constraints.append(contentsOf: [
                container.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: -.ecosia.space._s),
                container.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: .ecosia.space._s),
                container.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: .ecosia.space._2l
                )
            ])
        } else {
            constraints.append(contentsOf: [
                container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
        activeErrorToastContainer = container
        return container
    }

    private var activeErrorToastContainer: EcosiaErrorToastContainerView? {
        get {
            objc_getAssociatedObject(self, &EcosiaErrorToastAssociatedKeys.container)
                as? EcosiaErrorToastContainerView
        }
        set {
            objc_setAssociatedObject(
                self,
                &EcosiaErrorToastAssociatedKeys.container,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
