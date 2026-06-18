// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class OmniboxUploadDrawerViewController: UIViewController, Themeable {

    private enum UX {
        static let scrimAlpha: CGFloat = 0.5
        static let iPadWidthMultiplier: CGFloat = 0.6
        static let iPadMaxWidth: CGFloat = 400
        static let sheetSidePadding: CGFloat = .ecosia.space._2l
        static let panDismissDistance: CGFloat = 80
        static let panDismissVelocity: CGFloat = 800
        static let animationDuration: TimeInterval = 0.25
    }

    let windowUUID: WindowUUID
    var currentWindowUUID: WindowUUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    weak var delegate: OmniboxUploadDrawerDelegate?

    private var activeSheetConstraints: [NSLayoutConstraint] = []

    private lazy var scrimView: UIView = .build { view in
        view.backgroundColor = UIColor.black.withAlphaComponent(UX.scrimAlpha)
        view.alpha = 0
        view.isAccessibilityElement = true
        view.accessibilityLabel = String.localized(.cancel)
        view.accessibilityTraits = .button
        view.accessibilityHint = String.localized(.uploadDismissAccessibilityHint)
    }

    private lazy var sheetView: OmniboxUploadDrawerContentView = {
        let view = OmniboxUploadDrawerContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var hasAnimatedPresentation = false

    var contentViewForTesting: OmniboxUploadDrawerContentView { sheetView }

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true

        let scrimTap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        scrimView.addGestureRecognizer(scrimTap)

        view.addSubview(scrimView)
        view.addSubview(sheetView)

        sheetView.onOptionSelected = { [weak self] option in
            guard let self else { return }
            let sourceView = self.sheetView.optionViews.first { $0.option == option } ?? self.sheetView
            self.delegate?.omniboxUploadDrawer(self, didSelect: option, sourceView: sourceView)
        }

        sheetView.accessibilityLabel = String.localized(.uploadDrawerAccessibilityLabel)

        NSLayoutConstraint.activate([
            scrimView.topAnchor.constraint(equalTo: view.topAnchor),
            scrimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupSheetConstraints()
        setupPanGesture()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        animatePresentationIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        animatePresentationIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else { return }
        setupSheetConstraints()
    }

    private func setupSheetConstraints() {
        NSLayoutConstraint.deactivate(activeSheetConstraints)

        var constraints = [
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]

        if traitCollection.horizontalSizeClass == .regular {
            let widthConstraint = sheetView.widthAnchor.constraint(
                equalTo: view.widthAnchor,
                multiplier: UX.iPadWidthMultiplier
            )
            widthConstraint.priority = .defaultHigh
            constraints.append(contentsOf: [
                widthConstraint,
                sheetView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.iPadMaxWidth),
                sheetView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                   constant: UX.sheetSidePadding),
                sheetView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                    constant: -UX.sheetSidePadding)
            ])
        } else {
            constraints.append(contentsOf: [
                sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
        activeSheetConstraints = constraints
    }

    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetView.addGestureRecognizer(pan)
    }

    private func animatePresentationIfNeeded() {
        guard !hasAnimatedPresentation else { return }
        let sheetHeight = sheetView.bounds.height
        guard sheetHeight > 0 else { return }
        hasAnimatedPresentation = true

        sheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        UIView.animate(withDuration: UX.animationDuration,
                       delay: 0,
                       options: [.curveEaseOut]) {
            self.scrimView.alpha = 1
            self.sheetView.transform = .identity
        }
    }

    @objc private func dismissTapped() {
        dismissDrawer()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            let offset = max(0, translation.y)
            sheetView.transform = CGAffineTransform(translationX: 0, y: offset)
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            if translation.y > UX.panDismissDistance || velocity > UX.panDismissVelocity {
                dismissDrawer()
            } else {
                UIView.animate(withDuration: UX.animationDuration) {
                    self.sheetView.transform = .identity
                }
            }
        default:
            break
        }
    }

    func dismissDrawer(completion: (() -> Void)? = nil) {
        view.layoutIfNeeded()
        let sheetHeight = max(sheetView.bounds.height, 1)
        UIView.animate(withDuration: UX.animationDuration,
                       animations: {
            self.scrimView.alpha = 0
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        }, completion: { _ in
            self.dismiss(animated: false) {
                self.delegate?.omniboxUploadDrawerDidDismiss(self)
                completion?()
            }
        })
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        sheetView.applyTheme(theme: theme)
    }
}
