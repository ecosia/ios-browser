// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class EmptyBookmarksView: UIView, NotificationThemeable {
    
    private enum UX {
        static let TitleLabelFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        static let SectionLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let LearnMoreButtonLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let ImportButtonLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let ImportButtonPaddingInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        static let LayoutMargingsInset: CGFloat = 12
        static let ImportButtonBorderWidth: CGFloat = 1
        static let ImportButtonCornerRadius: CGFloat = 20
        static let TitleSpacerHeight: CGFloat = 24
        static let SurroundingSpacerWidth: CGFloat = 32
        static let InBetweenSpacerWidth: CGFloat = 6
        static let SectionSpacerWidth: CGFloat = 36
        static let SectionIconLabelSpacerWidth: CGFloat = 24
        static let SectionEndSpacerHeight: CGFloat = 16
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = .localized(.noBookmarksYet)
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
    
    private let learnMoreButton: UIButton = {
       let button = UIButton()
        button.setTitle(.localized(.learnMore), for: .normal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    private let importBookmarksButton: UIButton = {
       let button = UIButton()
        button.setTitle(.localized(.importBookmarks), for: .normal)
        button.layer.borderWidth = UX.ImportButtonBorderWidth
        button.layer.cornerRadius = UX.ImportButtonCornerRadius
        button.setInsets(
            forContentPadding: UX.ImportButtonPaddingInset,
            imageTitlePadding: 0
        )
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    weak var delegate: EmptyBookmarksViewDelegate?
    
    var bottomMarginConstraint: NSLayoutConstraint?
    
    required init?(coder: NSCoder) {
        assertionFailure("This view is only supposed to be instantiated programmatically")
        return nil
    }

    init(
        initialBottomMargin: CGFloat
    ) {
        super.init(frame: .zero)
        setup(initialBottomMargin)
    }
    
    private func setup(_ initialBottomMargin: CGFloat) {
        addSubview(containerStackView)
        
        bottomMarginConstraint = containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: initialBottomMargin)
        
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: UX.LayoutMargingsInset),
            containerStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -UX.LayoutMargingsInset),
            bottomMarginConstraint,
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ].compactMap { $0 })
        
        // title
        containerStackView.addArrangedSubview(titleLabel)
        
        // space between title and first section
        let spacerOne = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.TitleSpacerHeight).isActive = true
        }
        containerStackView.addArrangedSubview(spacerOne)
        
        addSection(imageNamed: "bookmarkAdd", text: .localized(.bookmarksEmptyViewItem0))
        addSection(imageNamed: "exportShare", text: .localized(.bookmarksEmptyViewItem1))
        
        let buttonStackViewSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.TitleSpacerHeight / 2).isActive = true
        }
        containerStackView.addArrangedSubview(buttonStackViewSpacer)

        let buttonsStackView = UIStackView(arrangedSubviews: [
            createSpacerView(width: UX.SurroundingSpacerWidth),
            learnMoreButton,
            createSpacerView(width: UX.InBetweenSpacerWidth),
            importBookmarksButton,
            createSpacerView(width: UX.SurroundingSpacerWidth)
        ])
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .equalCentering
        containerStackView.addArrangedSubview(buttonsStackView)
        
        // setup buttons
        learnMoreButton.addTarget(self, action: #selector(onLearnMoreTapped), for: .touchUpInside)
        importBookmarksButton.addTarget(self, action: #selector(onImportTapped), for: .touchUpInside)

        applyTheme()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
    }
    
    private func addSection(imageNamed: String, text: String) {
        // first section (tap the bookmark icon when you find a page you want to share)
        let sectionStackView = UIStackView()
        sectionStackView.axis = .horizontal
        sectionStackView.alignment = .top
        
        if traitCollection.userInterfaceIdiom == .pad {
            sectionStackView.addArrangedSubview(createSpacerView(width: UX.SectionSpacerWidth))
        }
        
        let sectionIcon = UIImageView()
        sectionIcon.tintColor = .theme.ecosia.secondaryText
        sectionIcon.contentMode = .scaleAspectFit
        sectionIcon.image = UIImage.templateImageNamed(imageNamed)
        sectionIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        sectionStackView.addArrangedSubview(sectionIcon)
        
        let sectionOneIconLabelSpacer = UIView.build {
            $0.widthAnchor.constraint(equalToConstant: UX.SectionIconLabelSpacerWidth).isActive = true
        }
        sectionStackView.addArrangedSubview(sectionOneIconLabelSpacer)
        
        let sectionLabel = UILabel()
        sectionLabel.font = UX.SectionLabelFont
        sectionLabel.numberOfLines = 0
        sectionLabel.textColor = .theme.ecosia.secondaryText
        sectionLabel.text = text
        sectionLabel.adjustsFontForContentSizeCategory = true
        sectionStackView.addArrangedSubview(sectionLabel)
        
        if traitCollection.userInterfaceIdiom == .pad {
            sectionStackView.addArrangedSubview(createSpacerView(width: UX.SectionSpacerWidth))
        }
                
        containerStackView.addArrangedSubview(sectionStackView)
        
        let sectionEndSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.SectionEndSpacerHeight).isActive = true
        }
        
        containerStackView.addArrangedSubview(sectionEndSpacer)
    }
    
    private func createSpacerView(width: CGFloat) -> UIView {
        UIView.build {
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            $0.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
    @objc private func onLearnMoreTapped() {
        Analytics.shared.bookmarksEmptyLearnMoreClicked()
        delegate?.emptyBookmarksViewLearnMoreTapped(self)
    }
    
    @objc private func onImportTapped() {
        delegate?.emptyBookmarksViewImportBookmarksTapped(self)
    }
    
    @objc func applyTheme() {
        importBookmarksButton.layer.borderColor = UIColor.theme.ecosia.primaryText.cgColor
        learnMoreButton.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        learnMoreButton.titleLabel?.font = UX.LearnMoreButtonLabelFont
        importBookmarksButton.setTitleColor(.theme.ecosia.primaryText, for: .normal)
        importBookmarksButton.titleLabel?.font = UX.ImportButtonLabelFont
        titleLabel.textColor = .theme.ecosia.primaryText
        containerStackView.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews }
            .reduce([UIView](), { partialResult, subViews in
                var finalResult = partialResult
                finalResult.append(contentsOf: subViews)
                return finalResult
            })
            .forEach {
                switch $0 {
                case let label as UILabel:
                    label.textColor = .theme.ecosia.primaryText
                default:
                    $0.tintColor = .theme.ecosia.primaryText
                    break
                }
            }
    }
}
