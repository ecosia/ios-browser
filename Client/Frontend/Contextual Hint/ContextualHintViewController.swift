// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

class ContextualHintViewController: UIViewController, OnViewDismissable, NotificationThemeable {

    struct UX {
        static let closeButtonSize = CGSize(width: 56, height: 56)

        static let labelLeading: CGFloat = 16
        static let labelTop: CGFloat = 8
        static let labelBottom: CGFloat = 16

        static let padding: CGFloat = 32
    }

    // MARK: - UI Elements
    private lazy var containerView: UIView = .build { [weak self] view in
        view.backgroundColor = .clear
    }

    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(.init(named: "tab_close"),
                        for: .normal)
        button.addTarget(self,
                         action: #selector(self?.dismissAnimated),
                         for: .touchUpInside)
        button.accessibilityLabel = String.ContextualHints.ContextualHintsCloseAccessibility
    }

    private lazy var descriptionLabel: UILabel = .build { [weak self] label in
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var actionButton: UIButton = .build { [weak self] button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.contentEdgeInsets = .init(top: 6, left: 12, bottom: 6, right: 12)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.addTarget(self,
                         action: #selector(self?.performAction),
                         for: .touchUpInside)
    }

    private lazy var stackView: UIStackView = .build { [weak self] stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = 4
    }

    /*
    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.colors = [
            UIColor.Photon.Violet40.cgColor,
            UIColor.Photon.Violet70.cgColor
        ]
        gradient.startPoint = CGPoint(x: 1, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0, 0.63]
        return gradient
    }()
     */

    // MARK: - Properties
    private (set) var viewModel: ContextualHintViewModel

    private var onViewSummoned: (() -> Void)?
    var onViewDismissed: (() -> Void)?
    private var onActionTapped: (() -> Void)?
    private var topContainerConstraint: NSLayoutConstraint?
    private var bottomContainerConstraint: NSLayoutConstraint?

    var isPresenting: Bool = false

    private var popupContentHeight: CGFloat {
        let spacingWidth = UX.labelLeading + UX.closeButtonSize.width
        let labelHeight = descriptionLabel.heightForLabel(
            descriptionLabel,
            width: UIScreen.main.bounds.width - UX.padding - spacingWidth,
            text: viewModel.descriptionText(arrowDirection: viewModel.arrowDirection))

        switch viewModel.isActionType() {
        case true:
            guard let titleLabel = actionButton.titleLabel else { fallthrough }
            let buttonHeight = titleLabel.heightForLabel(
                titleLabel,
                width: containerView.frame.width - spacingWidth,
                text: viewModel.buttonActionText())
            let totalHeight = buttonHeight + labelHeight + UX.labelTop + UX.labelBottom + stackView.spacing + actionButton.contentEdgeInsets.top + actionButton.contentEdgeInsets.bottom
            return totalHeight

        case false:
            return labelHeight + UX.labelTop + UX.labelBottom
        }
    }

    // MARK: - Initializers
    init(with viewModel: ContextualHintViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        isPresenting = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewSummoned?()
        onViewSummoned = nil
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Portrait orientation: lock enable
        OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.portrait,
                                              andRotateTo: UIInterfaceOrientation.portrait)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width-UX.padding, height: popupContentHeight)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.markContextualHintPresented()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Portrait orientation: lock disable
        OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.sendTelemetryEvent(for: .tapToDismiss)
        isPresenting = false
        onViewDismissed?()
        onViewDismissed = nil
    }

    private func commonInit() {
        setupView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayThemeChanged),
            name: .DisplayThemeChanged,
            object: nil)

    }

    private func setupView() {

        stackView.addArrangedSubview(descriptionLabel)
        if viewModel.isActionType() { stackView.addArrangedSubview(actionButton) }

        containerView.addSubview(closeButton)
        containerView.addSubview(stackView)
        view.addSubview(containerView)

        setupConstraints()
        toggleArrowBasedConstraints()
        applyTheme()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                               constant: UX.labelLeading),
            stackView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        topContainerConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor)
        topContainerConstraint?.isActive = true
        bottomContainerConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomContainerConstraint?.isActive = true

        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
    }

    private func toggleArrowBasedConstraints() {
        let topPadding = viewModel.arrowDirection == .up ? UX.labelBottom : UX.labelTop
        let bottomPadding = viewModel.arrowDirection == .up ? UX.labelTop : UX.labelBottom

        topContainerConstraint?.constant = topPadding
        bottomContainerConstraint?.constant = -bottomPadding

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func setupContent() {
        descriptionLabel.text = viewModel.descriptionText(arrowDirection: viewModel.arrowDirection)

        if viewModel.isActionType() {
           actionButton.setTitle(viewModel.buttonActionText(), for: .normal)
        }
    }

    // MARK: - Button Actions
    @objc private func dismissAnimated() {
        viewModel.sendTelemetryEvent(for: .closeButton)
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func performAction() {
        self.viewModel.sendTelemetryEvent(for: .performAction)
        self.dismiss(animated: true) {
            self.onActionTapped?()
            self.onActionTapped = nil
        }
    }

    // MARK: - Interface
    public func shouldPresentHint() -> Bool {
        return viewModel.shouldPresentContextualHint()
    }

    public func configure(
        anchor: UIView,
        withArrowDirection arrowDirection: UIPopoverArrowDirection,
        andDelegate delegate: UIPopoverPresentationControllerDelegate,
        presentedUsing presentation: (() -> Void)?,
        withActionBeforeAppearing preAction: (() -> Void)? = nil,
        actionOnDismiss postAction: (() -> Void)? = nil,
        andActionForButton buttonAction: (() -> Void)? = nil,
        andShouldStartTimerRightAway shouldStartTimer: Bool = true,
        onHintConfigured completion: (() -> Void)? = nil
    ) {
        stopTimer()
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.sourceView = anchor
        self.popoverPresentationController?.permittedArrowDirections = arrowDirection
        self.popoverPresentationController?.delegate = delegate
        self.onViewSummoned = preAction
        self.onViewDismissed = postAction
        self.onActionTapped = buttonAction
        viewModel.presentFromTimer = presentation
        viewModel.arrowDirection = arrowDirection

        setupContent()
        toggleArrowBasedConstraints()
        if viewModel.shouldPresentContextualHint() && shouldStartTimer {
            viewModel.startTimer()
        }

        completion?()
    }

    public func stopTimer() {
        viewModel.stopTimer()
    }

    public func startTimer() {
        viewModel.startTimer()
    }

    @objc func displayThemeChanged() {
        applyTheme()
        setupContent()
    }

    func applyTheme() {
        view.backgroundColor = .theme.ecosia.quarternaryBackground
        descriptionLabel.textColor = .theme.ecosia.primaryTextInverted
        closeButton.tintColor = .theme.ecosia.primaryTextInverted
        actionButton.setTitleColor(.Light.Text.primary, for: .normal)
        actionButton.setBackgroundColor(.Light.Background.primary, forState: .normal)
    }
}
