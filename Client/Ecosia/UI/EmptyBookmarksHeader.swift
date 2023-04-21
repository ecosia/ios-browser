// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class EmptyBookmarksHeader: UIView, NotificationThemeable {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = .localized(.noBookmarksYet)
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .subheadline).bold()
        return label
    }()
    
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    var bottomMarginConstraint: NSLayoutConstraint?
    
    init() {
        super.init(frame: .zero)
        setup()
//        self.icon = icon
//        super.init(reuseIdentifier: "EmptyHeader")
//        frame.size.height = 170
//
//        let image = UIImageView()
//        image.translatesAutoresizingMaskIntoConstraints = false
//        image.clipsToBounds = true
//        image.contentMode = .center
//        contentView.addSubview(image)
//        self.image = image
//
//        let labelTitle = UILabel()
//        labelTitle.translatesAutoresizingMaskIntoConstraints = false
//        labelTitle.numberOfLines = 0
//        labelTitle.text = title
//        labelTitle.font = .preferredFont(forTextStyle: .subheadline).bold()
//        labelTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        labelTitle.adjustsFontForContentSizeCategory = true
//        labelTitle.textAlignment = .center
//        contentView.addSubview(labelTitle)
//        self.labelTitle = labelTitle
//
//        let labelSubtitle = UILabel()
//        labelSubtitle.translatesAutoresizingMaskIntoConstraints = false
//        labelSubtitle.numberOfLines = 0
//        labelSubtitle.text = subtitle
//        labelSubtitle.font = .preferredFont(forTextStyle: .subheadline)
//        labelSubtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        labelSubtitle.adjustsFontForContentSizeCategory = true
//        labelSubtitle.textAlignment = .center
//        contentView.addSubview(labelSubtitle)
//        self.labelSubtitle = labelSubtitle
//
//        image.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32).isActive = true
//        image.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
//
//        labelTitle.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 12).isActive = true
//        labelTitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
//        labelTitle.widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
//
//        labelSubtitle.topAnchor.constraint(equalTo: labelTitle.bottomAnchor, constant: 4).isActive = true
//        labelSubtitle.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
//        labelSubtitle.widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
    }
    
    private func setup() {
        addSubview(containerStackView)
        
        bottomMarginConstraint = containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
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
        
        addSection(imageNamed: "bookmarksEmpty", text: "Tap the bookmark icon when you find a page you want to save")
        addSection(imageNamed: "downloadsEmpty", text: "You can also import bookmarks:\n1. Export your bookmarks from another browser.\n2. Tap on the link below to import the file with your bookmarks.")

    }
    
    private func addSection(imageNamed: String, text: String) {
        // first section (tap the bookmark icon when you find a page you want to share)
        let sectionOneStackView = UIStackView()
        sectionOneStackView.axis = .horizontal
        sectionOneStackView.alignment = .top
        
        let sectionOneIcon = UIImageView()
        sectionOneIcon.tintColor = .theme.ecosia.secondaryText
        sectionOneIcon.contentMode = .scaleAspectFit
        sectionOneIcon.image = UIImage.templateImageNamed(imageNamed)
        sectionOneIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        sectionOneStackView.addArrangedSubview(sectionOneIcon)
        
        let sectionOneIconLabelSpacer = UIView.build {
            $0.widthAnchor.constraint(equalToConstant: 24).isActive = true
        }
        sectionOneStackView.addArrangedSubview(sectionOneIconLabelSpacer)
        
        let sectionOneLabel = UILabel()
        sectionOneLabel.numberOfLines = 0
        sectionOneLabel.textColor = .theme.ecosia.secondaryText
        sectionOneLabel.text = text
        sectionOneStackView.addArrangedSubview(sectionOneLabel)
                
        containerStackView.addArrangedSubview(sectionOneStackView)
        
        let sectionEndSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: 16).isActive = true
        }
        
        containerStackView.addArrangedSubview(sectionEndSpacer)
    }
    
    func applyTheme() {
//        image?.image = .init(named: icon)?.withRenderingMode(.alwaysTemplate)
//        image?.tintColor = UIColor.theme.ecosia.secondaryText
//        labelTitle?.textColor = .theme.ecosia.primaryText
//        labelSubtitle?.textColor = .theme.ecosia.secondaryText
        titleLabel.textColor = .theme.ecosia.primaryText
    }
}
