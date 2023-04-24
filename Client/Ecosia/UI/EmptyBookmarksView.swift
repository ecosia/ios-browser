// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class EmptyBookmarksView: UIView, NotificationThemeable {

    required init?(coder: NSCoder) {
        assertionFailure("This view is only supposed to be instantiated programmatically")
        return nil
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = .localized(.noBookmarksYet)
        label.textAlignment = .center
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        return label
    }()
    
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    private let learnMoreButton: UIButton = {
       let button = UIButton()
        button.setTitle("Learn more", for: .normal)
        return button
    }()
    
    private let importBookmarksButton: UIButton = {
       let button = UIButton()
        button.setTitle("Import bookmarks", for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 22
        button.setInsets(
            forContentPadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
            imageTitlePadding: 0
        )
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return button
    }()
    
    private let learnMoreHandler: () -> Void
    private let importBookmarksHandler: () -> Void
    
    var bottomMarginConstraint: NSLayoutConstraint?

    init(
        initialBottomMargin: CGFloat,
        learnMoreHandler: @escaping () -> Void,
        importBookmarksHandler: @escaping () -> Void
    ) {
        self.learnMoreHandler = learnMoreHandler
        self.importBookmarksHandler = importBookmarksHandler
        super.init(frame: .zero)
        setup(initialBottomMargin)
    }
    
    private func setup(_ initialBottomMargin: CGFloat) {
        addSubview(containerStackView)
        
        bottomMarginConstraint = containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: initialBottomMargin)
        
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 12),
            containerStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -12),
            bottomMarginConstraint,
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ].compactMap { $0 })
        
        // title
        containerStackView.addArrangedSubview(titleLabel)
        
        // space between title and first section
        let spacerOne = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: 24).isActive = true
        }
        containerStackView.addArrangedSubview(spacerOne)
        
        addSection(imageNamed: "bookmarkAdd", text: "Tap the bookmark icon when you find a page you want to save")
        addSection(imageNamed: "exportShare", text: "You can also import bookmarks:\n1. Export your bookmarks from another browser.\n2. Tap on the link below to import the file with your bookmarks.")
        
        let buttonStackViewSpacer = UIView.build {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 12).isActive = true
        }
        containerStackView.addArrangedSubview(buttonStackViewSpacer)

        let buttonsStackView = UIStackView(arrangedSubviews: [
            createSpacerView(width: 36),
            learnMoreButton,
            importBookmarksButton,
            createSpacerView(width: 36)
        ])
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fill
        containerStackView.addArrangedSubview(buttonsStackView)
        
        // setup buttons
        learnMoreButton.addTarget(self, action: #selector(onLearnMoreTapped), for: .touchUpInside)
        importBookmarksButton.addTarget(self, action: #selector(onImportTapped), for: .touchUpInside)

        applyTheme()
    }
    
    private func addSection(imageNamed: String, text: String) {
        // first section (tap the bookmark icon when you find a page you want to share)
        let sectionStackView = UIStackView()
        sectionStackView.axis = .horizontal
        sectionStackView.alignment = .top
        
        let sectionIcon = UIImageView()
        sectionIcon.tintColor = .theme.ecosia.secondaryText
        sectionIcon.contentMode = .scaleAspectFit
        sectionIcon.image = UIImage.templateImageNamed(imageNamed)
        sectionIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        sectionStackView.addArrangedSubview(sectionIcon)
        
        let sectionOneIconLabelSpacer = UIView.build {
            $0.widthAnchor.constraint(equalToConstant: 24).isActive = true
        }
        sectionStackView.addArrangedSubview(sectionOneIconLabelSpacer)
        
        let sectionLabel = UILabel()
        sectionLabel.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        sectionLabel.numberOfLines = 0
        sectionLabel.textColor = .theme.ecosia.secondaryText
        sectionLabel.text = text
        sectionStackView.addArrangedSubview(sectionLabel)
                
        containerStackView.addArrangedSubview(sectionStackView)
        
        let sectionEndSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: 16).isActive = true
        }
        
        containerStackView.addArrangedSubview(sectionEndSpacer)
    }
    
    private func createSpacerView(width: CGFloat) -> UIView {
        UIView.build {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            $0.widthAnchor.constraint(equalToConstant: 36).isActive = true
        }
    }
    
    @objc private func onLearnMoreTapped() {
        learnMoreHandler()
    }
    
    @objc private func onImportTapped() {
        importBookmarksHandler()
    }
    
    func applyTheme() {
        importBookmarksButton.layer.borderColor = UIColor.theme.ecosia.primaryText.cgColor
        learnMoreButton.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        importBookmarksButton.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        titleLabel.textColor = .theme.ecosia.primaryText
    }
}
