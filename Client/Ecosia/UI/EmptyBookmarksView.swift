// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class EmptyBookmarksView: UIView, NotificationThemeable {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(0)
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
    
    var bottomMarginConstraint: NSLayoutConstraint?

    init(initialBottomMargin: CGFloat) {
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
    
    func applyTheme() {
        titleLabel.textColor = .theme.ecosia.primaryText
    }
}
