// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia

final class TrackingProtectionToggleView: UIView, ThemeApplicable {
    private struct UX {
        static let toggleLabelsContainerConstraintConstant = 16.0
    }

    var toggleSwitchedCallback: (() -> Void)?

    private let toggleLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = TPMenuUX.UX.headerLabelDistance
    }

    private let toggleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    /* Ecosia: Use themed Switch
    private let toggleSwitch: UISwitch = .build { toggleSwitch in
     */
    private let toggleSwitch: EcosiaThemedSwitch = .build { toggleSwitch in
        toggleSwitch.isEnabled = true
    }

    private let toggleStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private var viewConstraints: [NSLayoutConstraint] = []

    var toggleIsOn: Bool {
        toggleSwitch.isOn
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false

        toggleLabelsContainer.addArrangedSubview(toggleLabel)
        toggleLabelsContainer.addArrangedSubview(toggleStatusLabel)
        self.addSubviews(toggleLabelsContainer, toggleSwitch)
    }

    private func updateLayout(isAccessibilityCategory: Bool) {
        removeConstraints(constraints)
        viewConstraints.removeAll()
        viewConstraints.append(contentsOf: [
            toggleLabelsContainer.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            toggleLabelsContainer.trailingAnchor.constraint(
                equalTo: toggleSwitch.leadingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            toggleLabelsContainer.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.toggleLabelsContainerConstraintConstant
            ),
            toggleLabelsContainer.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -UX.toggleLabelsContainerConstraintConstant
            ),
            toggleSwitch.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            )
        ])
        if !isAccessibilityCategory {
            viewConstraints.append(toggleSwitch.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        } else {
            viewConstraints.append(toggleSwitch.topAnchor.constraint(
                equalTo: toggleLabelsContainer.topAnchor,
                constant: UX.toggleLabelsContainerConstraintConstant))
        }
        NSLayoutConstraint.activate(viewConstraints)
    }

    func adjustLayout() {
        updateLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
    }

    func setToggleSwitchVisibility(with isHidden: Bool) {
        toggleSwitch.isHidden = isHidden
    }

    func setStatusLabelText(with text: String) {
        toggleStatusLabel.text = text
    }

    func setupDetails(isOn: Bool) {
        toggleSwitch.isOn = isOn
        toggleLabel.text = .Menu.EnhancedTrackingProtection.switchTitle
        toggleStatusLabel.text = isOn ?
            .Menu.EnhancedTrackingProtection.switchOnText : .Menu.EnhancedTrackingProtection.switchOffText
    }

    func setupAccessibilityIdentifiers(toggleViewTitleLabelA11yId: String, toggleViewBodyLabelA11yId: String) {
        toggleLabel.accessibilityIdentifier = toggleViewTitleLabelA11yId
        toggleStatusLabel.accessibilityIdentifier = toggleViewBodyLabelA11yId
    }

    func setupActions() {
        toggleSwitch.addTarget(self, action: #selector(trackingProtectionToggleTapped), for: .valueChanged)
    }

    @objc
    func trackingProtectionToggleTapped() {
        toggleSwitchedCallback?()
    }

    func applyTheme(theme: Theme) {
        /* Ecosia: Update background color
        self.backgroundColor = theme.colors.layer2
         */
        self.backgroundColor = theme.colors.ecosia.backgroundElevation1
        /* Ecosia: Use applyTheme from EcosiaThemedSwitch
        toggleSwitch.tintColor = theme.colors.actionPrimary
        toggleSwitch.onTintColor = theme.colors.actionPrimary
         */
        toggleSwitch.applyTheme(theme: theme)
        toggleStatusLabel.textColor = theme.colors.textSecondary
    }
}
