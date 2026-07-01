// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

private enum EcosiaErrorToastContainerUX {
    static let depthPeekOffset: CGFloat = .ecosia.space._s
    static let depthScaleStep: CGFloat = 0.04
    static let presentationAnimationDuration: TimeInterval = 0.3
    static let removalAnimationDuration: TimeInterval = 0.25
    static let displayDuration: TimeInterval = 4.5
    static let rowMinHeight: CGFloat = 56
}

private struct EcosiaErrorToastAssociatedKeys {
    nonisolated(unsafe) static var container: UInt8 = 0
}

/// Hosts one SwiftUI error row inside the z-stacked toast container.
@available(iOS 16.0, *)
@MainActor
private final class EcosiaErrorToastRowHost: UIView {
    private var hostingController: UIHostingController<EcosiaErrorToastRowContent>?

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
                onCloseTapped: onClose
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
    }

    func teardown() {
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }
}

/// Fixed top-aligned container. Toasts overlap on the z-axis: first in at the back, last in on top.
@available(iOS 16.0, *)
@MainActor
final class EcosiaErrorToastContainerView: UIView {
    private var rows: [EcosiaErrorToastRowHost] = []
    private var heightConstraint: NSLayoutConstraint?
    private var autoDismissWorkItem: DispatchWorkItem?

    private weak var parentViewController: UIViewController?
    private var windowUUID: WindowUUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = true

        let heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(parent: UIViewController, windowUUID: WindowUUID) {
        parentViewController = parent
        self.windowUUID = windowUUID
    }

    /// Appends errors in order; the first message sits at the back, the last is on top.
    func present(messages: [String]) {
        guard !messages.isEmpty,
              let parentViewController,
              let windowUUID else { return }

        let wasEmpty = rows.isEmpty
        var newRows: [EcosiaErrorToastRowHost] = []

        for message in messages {
            let row = makeRow(message: message, windowUUID: windowUUID, parent: parentViewController)
            rows.append(row)
            newRows.append(row)
        }

        layoutIfNeeded()

        UIView.animate(
            withDuration: EcosiaErrorToastContainerUX.presentationAnimationDuration,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState],
            animations: {
                self.applyStackLayout()
                newRows.forEach { row in
                    row.alpha = 1
                }
                parentViewController.view.layoutIfNeeded()
            }
        )

        scheduleFrontRowAutoDismiss()

        if wasEmpty, let firstMessage = messages.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIAccessibility.post(notification: .announcement, argument: firstMessage)
            }
        }
    }

    func clear() {
        cancelAutoDismiss()
        rows.forEach { $0.teardown() }
        rows.forEach { $0.removeFromSuperview() }
        rows.removeAll()
        heightConstraint?.constant = 0
    }

    private func makeRow(
        message: String,
        windowUUID: WindowUUID,
        parent: UIViewController
    ) -> EcosiaErrorToastRowHost {
        let row = EcosiaErrorToastRowHost()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.alpha = 0
        addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor)
        ])

        row.install(
            message: message,
            windowUUID: windowUUID,
            parent: parent,
            onClose: { [weak self, weak row] in
                guard let self, let row else { return }
                self.removeFrontRow(row)
            }
        )

        return row
    }

    /// FILO: only the front (most recently added) row can be dismissed.
    private func removeFrontRow(_ row: EcosiaErrorToastRowHost) {
        guard rows.last === row else { return }
        removeRow(row)
    }

    private func removeRow(_ row: EcosiaErrorToastRowHost) {
        guard let index = rows.firstIndex(where: { $0 === row }) else { return }

        cancelAutoDismiss()

        UIView.animate(
            withDuration: EcosiaErrorToastContainerUX.removalAnimationDuration,
            delay: 0,
            options: [.curveEaseIn, .beginFromCurrentState],
            animations: {
                row.alpha = 0
                row.transform = CGAffineTransform(translationX: 0, y: -12)
                    .scaledBy(x: 0.96, y: 0.96)
                self.parentViewController?.view.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                guard let self else { return }
                row.teardown()
                row.removeFromSuperview()
                self.rows.remove(at: index)
                UIView.animate(
                    withDuration: EcosiaErrorToastContainerUX.presentationAnimationDuration,
                    animations: {
                        self.applyStackLayout()
                        self.parentViewController?.view.layoutIfNeeded()
                    },
                    completion: { _ in
                        self.scheduleFrontRowAutoDismiss()
                    }
                )
            }
        )
    }

    private func applyStackLayout() {
        let count = rows.count

        for (index, row) in rows.enumerated() {
            let depthFromFront = count - 1 - index
            let scale = max(0.88, 1 - CGFloat(depthFromFront) * EcosiaErrorToastContainerUX.depthScaleStep)
            let yOffset = -CGFloat(depthFromFront) * EcosiaErrorToastContainerUX.depthPeekOffset

            row.transform = CGAffineTransform(translationX: 0, y: yOffset)
                .scaledBy(x: scale, y: scale)
            row.layer.zPosition = CGFloat(index)
            row.isUserInteractionEnabled = depthFromFront == 0
        }

        updateContainerHeight()
    }

    private func updateContainerHeight() {
        guard let frontRow = rows.last else {
            heightConstraint?.constant = 0
            return
        }

        frontRow.layoutIfNeeded()
        let fittingWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        let frontHeight = frontRow.systemLayoutSizeFitting(
            CGSize(width: fittingWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let peekHeight = CGFloat(max(0, rows.count - 1)) * EcosiaErrorToastContainerUX.depthPeekOffset
        heightConstraint?.constant = max(frontHeight, EcosiaErrorToastContainerUX.rowMinHeight) + peekHeight
    }

    private func scheduleFrontRowAutoDismiss() {
        cancelAutoDismiss()
        guard rows.last != nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, let front = self.rows.last else { return }
            self.removeRow(front)
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

@available(iOS 16.0, *)
extension BrowserViewController {

    /// Shows one or more top-aligned error notifications in the fixed stack container.
    func showEcosiaErrorToasts(messages: [String]) {
        guard !messages.isEmpty else { return }
        let container = ensureEcosiaErrorToastContainer()
        container.present(messages: messages)
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

    @discardableResult
    private func ensureEcosiaErrorToastContainer() -> EcosiaErrorToastContainerView {
        if let container = activeErrorToastContainer {
            return container
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
