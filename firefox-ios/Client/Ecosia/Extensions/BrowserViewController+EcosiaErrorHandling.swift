// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

private enum EcosiaErrorToastContainerUX {
    static let rowSpacing: CGFloat = .ecosia.space._1s
    static let removalAnimationDuration: TimeInterval = 0.25
    static let displayDuration: TimeInterval = 4.5
}

private struct EcosiaErrorToastAssociatedKeys {
    nonisolated(unsafe) static var container: UInt8 = 0
}

/// Hosts one SwiftUI error row inside a UIKit stack view.
@available(iOS 16.0, *)
@MainActor
private final class EcosiaErrorToastRowHost: UIView {
    private var hostingController: UIHostingController<EcosiaErrorToastRowContent>?
    private var autoDismissWorkItem: DispatchWorkItem?

    func install(
        message: String,
        windowUUID: WindowUUID,
        parent: UIViewController,
        onClose: @escaping () -> Void
    ) {
        let hostingController = UIHostingController(
            rootView: EcosiaErrorToastRowContent(
                message: message,
                windowUUID: windowUUID,
                onCloseTapped: { [weak self] in
                    self?.cancelAutoDismiss()
                    onClose()
                }
            )
        )
        hostingController.view.backgroundColor = .clear
        hostingController.sizingOptions = [.intrinsicContentSize]
        self.hostingController = hostingController

        parent.addChild(hostingController)
        addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController.didMove(toParent: parent)

        scheduleAutoDismiss(onClose: onClose)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    func teardown() {
        cancelAutoDismiss()
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }

    private func scheduleAutoDismiss(onClose: @escaping () -> Void) {
        cancelAutoDismiss()

        let workItem = DispatchWorkItem { [weak self] in
            self?.cancelAutoDismiss()
            onClose()
        }
        autoDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + EcosiaErrorToastContainerUX.displayDuration,
            execute: workItem
        )
    }

    private func cancelAutoDismiss() {
        autoDismissWorkItem?.cancel()
        autoDismissWorkItem = nil
    }
}

/// Container view to host error toasts in a vertical UIKit stack.
/// Rows are removed with a layout animation; the container is removed when empty.
@available(iOS 16.0, *)
@MainActor
final class EcosiaErrorToastContainerView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = EcosiaErrorToastContainerUX.rowSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private weak var parentViewController: UIViewController?
    private var onDismiss: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(
        messages: [String],
        windowUUID: WindowUUID,
        in viewController: UIViewController,
        onDismiss: @escaping () -> Void
    ) {
        parentViewController = viewController
        self.onDismiss = onDismiss

        for message in messages {
            addRow(message: message, windowUUID: windowUUID)
        }
    }

    private func addRow(message: String, windowUUID: WindowUUID) {
        guard let parentViewController else { return }

        let row = EcosiaErrorToastRowHost()
        row.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(row)

        row.install(
            message: message,
            windowUUID: windowUUID,
            parent: parentViewController,
            onClose: { [weak self, weak row] in
                guard let self, let row else { return }
                self.removeRow(row)
            }
        )
    }

    private func removeRow(_ row: EcosiaErrorToastRowHost) {
        guard stackView.arrangedSubviews.contains(row) else { return }

        UIView.animate(
            withDuration: EcosiaErrorToastContainerUX.removalAnimationDuration,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState],
            animations: {
                row.alpha = 0
                self.stackView.removeArrangedSubview(row)
                row.removeFromSuperview()
                self.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                row.teardown()
                self?.removeContainerIfEmpty()
            }
        )
    }

    private func removeContainerIfEmpty() {
        guard stackView.arrangedSubviews.isEmpty else { return }

        removeFromSuperview()
        onDismiss?()
        onDismiss = nil
    }

    func tearDownAllRows() {
        stackView.arrangedSubviews
            .compactMap { $0 as? EcosiaErrorToastRowHost }
            .forEach { $0.teardown() }
    }
}

@available(iOS 16.0, *)
extension BrowserViewController {

    /// Shows one or more top-aligned error notifications.
    func showEcosiaErrorToasts(messages: [String]) {
        guard !messages.isEmpty else { return }
        dismissEcosiaErrorToastIfNeeded()

        let container = EcosiaErrorToastContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        view.bringSubviewToFront(container)

        activeErrorToastContainer = container

        var constraints: [NSLayoutConstraint] = []

        if let homepage = contentContainer.contentController as? HomepageViewController,
           let searchBar = homepage.ntpSearchBar,
           searchBar.window != nil {
            constraints.append(contentsOf: [
                container.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: -.ecosia.space._s),
                container.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: .ecosia.space._s),
                container.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: .ecosia.space._l
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

        container.show(
            messages: messages,
            windowUUID: windowUUID,
            in: self,
            onDismiss: { [weak self] in
                self?.activeErrorToastContainer = nil
            }
        )
    }

    /// Shows a single top-aligned error notification.
    func showEcosiaErrorToast(message: String) {
        showEcosiaErrorToasts(messages: [message])
    }

    /// Shows an error toast for auth flow failures
    /// - Parameters:
    ///   - isLogin: Whether this was a login (true) or logout (false) error
    func showAuthFlowErrorToast(isLogin: Bool, errorMessage: String? = nil) {
        var subtitle = isLogin
            ? String.localized(.signInErrorMessage)
            : String.localized(.signOutErrorMessage)

        #if MOZ_CHANNEL_BETA
        if let errorMessage {
            subtitle += "Additional details: \(errorMessage)"
        }
        #endif

        showEcosiaErrorToast(message: subtitle)
    }

    private func dismissEcosiaErrorToastIfNeeded() {
        activeErrorToastContainer?.tearDownAllRows()
        activeErrorToastContainer?.removeFromSuperview()
        activeErrorToastContainer = nil
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
