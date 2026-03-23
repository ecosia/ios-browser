// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

@MainActor
final class EmptyReadingListView: UIView, Themeable {

    private enum UX {
        static let TitleLabelFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        static let SectionLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let LayoutMarginsInset: CGFloat = 12
        static let TitleSpacerHeight: CGFloat = 24
        static let SectionIconLabelSpacerWidth: CGFloat = 24
        static let SectionEndSpacerHeight: CGFloat = 16
        static let SectionIconWidth: CGFloat = 18
        static let SectionContainerMaxWidth: CGFloat = 450
        static let TopPadding: CGFloat = 120
    }

    // MARK: - Themeable Properties

    let windowUUID: WindowUUID
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Properties

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = .ReaderPanelWelcome
        label.textAlignment = .center
        label.font = UX.TitleLabelFont
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        assertionFailure("This view is only supposed to be instantiated programmatically")
        return nil
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: .zero)
        setup()
        applyTheme()
    }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerStackView)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor, constant: UX.LayoutMarginsInset),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, constant: -UX.LayoutMarginsInset),
            containerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.SectionContainerMaxWidth),
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.TopPadding),
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        // title
        containerStackView.addArrangedSubview(titleLabel)

        // space between title and first section
        let titleSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.TitleSpacerHeight).isActive = true
        }
        containerStackView.addArrangedSubview(titleSpacer)

        addSection(
            imageNamed: StandardImageIdentifiers.Large.readerView,
            text: .ReaderPanelReadingModeDescription
        )
        addSection(
            imageNamed: "addToReadingListUpdate",
            text: .ReaderPanelReadingListDescription
        )

        listenForThemeChanges(withNotificationCenter: notificationCenter)
    }

    private func addSection(imageNamed: String, text: String) {
        let sectionStackView = UIStackView()
        sectionStackView.axis = .horizontal
        sectionStackView.alignment = .top

        let sectionIcon = UIImageView()
        sectionIcon.contentMode = .scaleAspectFit
        sectionIcon.image = UIImage(named: imageNamed)?.withRenderingMode(.alwaysTemplate)
        sectionIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        sectionIcon.setContentHuggingPriority(.required, for: .horizontal)
        sectionIcon.translatesAutoresizingMaskIntoConstraints = false
        sectionIcon.widthAnchor.constraint(equalToConstant: UX.SectionIconWidth).priority(.required).isActive = true

        sectionStackView.addArrangedSubview(sectionIcon)

        let iconLabelSpacer = UIView.build {
            $0.widthAnchor.constraint(equalToConstant: UX.SectionIconLabelSpacerWidth).isActive = true
        }
        sectionStackView.addArrangedSubview(iconLabelSpacer)

        let sectionLabel = UILabel()
        sectionLabel.font = UX.SectionLabelFont
        sectionLabel.numberOfLines = 0
        sectionLabel.text = text
        sectionLabel.adjustsFontForContentSizeCategory = true
        sectionStackView.addArrangedSubview(sectionLabel)

        containerStackView.addArrangedSubview(sectionStackView)

        let sectionEndSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.SectionEndSpacerHeight).isActive = true
        }
        containerStackView.addArrangedSubview(sectionEndSpacer)
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        titleLabel.textColor = theme.colors.textPrimary

        for subview in containerStackView.arrangedSubviews {
            guard let stackView = subview as? UIStackView else { continue }
            for child in stackView.arrangedSubviews {
                if let label = child as? UILabel {
                    label.textColor = theme.colors.textSecondary
                } else if let imageView = child as? UIImageView {
                    imageView.tintColor = theme.colors.textSecondary
                }
            }
        }
    }
}
