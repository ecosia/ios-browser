/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

protocol TreesCellDelegate: AnyObject {
    func treesCellDidTapSpotlight(_ cell: TreesCell)
}

final class TreesCell: UICollectionViewCell, Themeable {

    private (set) var model: TreesCellModel?
    private let treeCounter = TreeCounter()
    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    weak var delegate: TreesCellDelegate?

    private weak var background: UIView!
    private weak var container: UIStackView!
    var widthConstraint: NSLayoutConstraint!


    private weak var spotlightBackground: UIView!
    private weak var spotlightContainerStack: UIStackView!
    private weak var spotlightStack: UIStackView!
    private weak var spotlightHeadline: UILabel!
    private weak var spotlightDescription: UILabel!
    private weak var spotlightClose: UIImageView!

    private weak var impactBackground: UIView!
    private weak var impactStack: UIStackView!
    private weak var personalImpactStack: UIStackView!
    private weak var personalImpactLabelStack: UIStackView!
    private weak var yourImpact: UILabel!
    private weak var treesPlanted: UILabel!

    private weak var globalCountStack: UIStackView!
    private weak var globalCount: UILabel!
    private weak var globalCountDescription: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let background = UIView()
        background.setContentHuggingPriority(.defaultLow, for: .horizontal)
        background.translatesAutoresizingMaskIntoConstraints = false
        background.layer.cornerRadius = 8
        contentView.addSubview(background)
        self.background = background

        let container = UIStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.distribution = .fill
        container.alignment = .fill
        container.setContentHuggingPriority(.required, for: .horizontal)
        container.backgroundColor = .clear
        contentView.addSubview(container)
        self.container = container

        addSpotlight()
        addImpact()
        addConstraints()
        applyTheme()

        treeCounter.subscribe(self) { [weak self] count in
            guard let self = self, self.model?.highlight == nil else { return }

            UIView.transition(with: self.globalCount, duration: 0.65, options: .transitionCrossDissolve, animations: {
                self.globalCount.text = self.formatter.string(from: .init(value: count))
            })
        }
        treeCounter.update(session: .shared) { _ in }
    }

    func display(_ model: TreesCellModel) {
        self.model = model

        spotlightViews.forEach { $0.isHidden = model.spotlight == nil }

        if let spotlight = model.spotlight {
            spotlightHeadline.text = spotlight.headline
            spotlightDescription.text = spotlight.description
        }
        applyTheme()
    }

    @objc func spotlightTapped() {
        delegate?.treesCellDidTapSpotlight(self)
    }

    var spotlightViews: [UIView] {
        return [spotlightBackground, spotlightContainerStack]
    }

    // MARK: UI
    private func addSpotlight() {
        let spotlightBackground = UIView()
        spotlightBackground.translatesAutoresizingMaskIntoConstraints = false
        spotlightBackground.layer.cornerRadius = 8
        container.addArrangedSubview(spotlightBackground)
        self.spotlightBackground = spotlightBackground

        spotlightBackground.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(spotlightTapped)))

        let spotlightContainerStack = UIStackView()
        spotlightContainerStack.axis = .horizontal
        spotlightContainerStack.alignment = .leading
        spotlightContainerStack.translatesAutoresizingMaskIntoConstraints = false
        spotlightBackground.addSubview(spotlightContainerStack)
        self.spotlightContainerStack = spotlightContainerStack

        let spotlightStack = UIStackView()
        spotlightStack.axis = .vertical
        spotlightStack.translatesAutoresizingMaskIntoConstraints = false
        spotlightStack.spacing = 0
        spotlightContainerStack.addArrangedSubview(spotlightStack)
        self.spotlightStack = spotlightStack

        let spotlightHeadline = UILabel()
        spotlightStack.addArrangedSubview(spotlightHeadline)
        spotlightHeadline.setContentCompressionResistancePriority(.required, for: .vertical)
        spotlightHeadline.setContentHuggingPriority(.defaultLow, for: .horizontal)

        spotlightHeadline.font = .preferredFont(forTextStyle: .subheadline).bold()
        spotlightHeadline.adjustsFontForContentSizeCategory = true
        spotlightHeadline.numberOfLines = 0
        self.spotlightHeadline = spotlightHeadline

        let spotlightDescription = UILabel()
        spotlightDescription.numberOfLines = 0
        spotlightDescription.font = .preferredFont(forTextStyle: .subheadline)
        spotlightDescription.adjustsFontForContentSizeCategory = true
        spotlightDescription.setContentCompressionResistancePriority(.required, for: .vertical)
        spotlightStack.addArrangedSubview(spotlightDescription)
        self.spotlightDescription = spotlightDescription

        let spotlightClose = UIImageView(image: .init(named: "close-medium")?.withRenderingMode(.alwaysTemplate))
        spotlightClose.contentMode = .scaleAspectFit
        spotlightClose.setContentHuggingPriority(.required, for: .horizontal)
        spotlightContainerStack.addArrangedSubview(spotlightClose)
        self.spotlightClose = spotlightClose
    }

    private func addImpact() {
        let impactBackground = UIView()
        impactBackground.setContentHuggingPriority(.defaultLow, for: .horizontal)
        impactBackground.translatesAutoresizingMaskIntoConstraints = false
        impactBackground.layer.cornerRadius = 8
        container.addArrangedSubview(impactBackground)
        self.impactBackground = impactBackground

        let impactStack = UIStackView()
        impactStack.axis = .vertical
        impactStack.spacing = 16
        impactStack.translatesAutoresizingMaskIntoConstraints = false
        impactBackground.addSubview(impactStack)
        self.impactStack = impactStack

        let personalImpactStack = UIStackView()
        personalImpactStack.axis = .horizontal
        personalImpactStack.spacing = 16
        personalImpactStack.translatesAutoresizingMaskIntoConstraints = false
        impactStack.addArrangedSubview(personalImpactStack)
        self.personalImpactStack = personalImpactStack

        let personalImpactLabelStack = UIStackView()
        personalImpactLabelStack.axis = .vertical
        personalImpactLabelStack.spacing = 4
        personalImpactLabelStack.translatesAutoresizingMaskIntoConstraints = false
        personalImpactStack.addArrangedSubview(personalImpactLabelStack)
        self.personalImpactLabelStack = personalImpactLabelStack

        let yourImpact = UILabel()
        yourImpact.text = .localized(.yourImpact)
        yourImpact.translatesAutoresizingMaskIntoConstraints = false
        yourImpact.font = .preferredFont(forTextStyle: .footnote)
        yourImpact.adjustsFontForContentSizeCategory = true
        yourImpact.setContentHuggingPriority(.defaultLow, for: .horizontal)
        yourImpact.setContentCompressionResistancePriority(.required, for: .vertical)
        yourImpact.setContentHuggingPriority(.init(751), for: .vertical) // to counter ambiguity
        personalImpactLabelStack.addArrangedSubview(yourImpact)
        self.yourImpact = yourImpact

        let treesPlanted = UILabel()
        treesPlanted.text = .localized(.treesPlanted)
        treesPlanted.translatesAutoresizingMaskIntoConstraints = false
        treesPlanted.font = .preferredFont(forTextStyle: .title3).bold()
        treesPlanted.setContentCompressionResistancePriority(.required, for: .vertical)
        treesPlanted.setContentHuggingPriority(.defaultHigh, for: .vertical)
        treesPlanted.adjustsFontForContentSizeCategory = true
        treesPlanted.numberOfLines = 0
        personalImpactLabelStack.addArrangedSubview(treesPlanted)
        self.treesPlanted = treesPlanted

        let globalCountStack = UIStackView()
        globalCountStack.axis = .vertical
        globalCountStack.distribution = .fill
        globalCountStack.spacing = 4
        impactStack.addArrangedSubview(globalCountStack)
        self.globalCountStack = globalCountStack

        let globalCountDescription = UILabel()
        globalCountDescription.textAlignment = .left
        globalCountDescription.translatesAutoresizingMaskIntoConstraints = false
        globalCountDescription.text = .localized(.treesPlantedByTheCommunity)
        globalCountDescription.font = .preferredFont(forTextStyle: .footnote)
        globalCountDescription.adjustsFontForContentSizeCategory = true
        globalCountDescription.setContentHuggingPriority(.defaultLow, for: .horizontal)
        globalCountDescription.numberOfLines = 0
        globalCountDescription.textAlignment = .left
        globalCountStack.addArrangedSubview(globalCountDescription)
        self.globalCountDescription = globalCountDescription

        let globalCountInnerStack = UIStackView()
        globalCountInnerStack.axis = .horizontal
        globalCountInnerStack.distribution = .fill
        globalCountInnerStack.spacing = 4
        globalCountStack.addArrangedSubview(globalCountInnerStack)

        let treesImage = UIImageView(image: .init(named: "trees"))
        treesImage.setContentHuggingPriority(.required, for: .horizontal)
        globalCountInnerStack.addArrangedSubview(treesImage)

        let globalCount = UILabel()
        globalCount.translatesAutoresizingMaskIntoConstraints = false
        globalCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        globalCount.setContentCompressionResistancePriority(.required, for: .vertical)
        globalCount.setContentHuggingPriority(.defaultLow, for: .horizontal)
        globalCount.font = .preferredFont(forTextStyle: .subheadline).bold().monospace()
        globalCount.adjustsFontForContentSizeCategory = true
        globalCount.textAlignment = .left

        globalCountInnerStack.addArrangedSubview(globalCount)
        self.globalCount = globalCount
    }

    private func addConstraints() {
        // Constraints for stack views to their backgrounds
        background.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40).isActive = true
        let bottom = background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        bottom.priority = .defaultHigh
        bottom.isActive = true

        let right = background.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        right.priority = .defaultHigh
        right.isActive = true

        let width = background.widthAnchor.constraint(equalToConstant: bounds.width)
        width.priority = .init(999)
        width.isActive = true
        self.widthConstraint = width

        background.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true

        container.rightAnchor.constraint(equalTo: background.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: background.topAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: background.leftAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: background.bottomAnchor).isActive = true

        spotlightContainerStack.rightAnchor.constraint(equalTo: spotlightBackground.rightAnchor, constant: -12).isActive = true
        spotlightContainerStack.topAnchor.constraint(equalTo: spotlightBackground.topAnchor, constant: 8).isActive = true
        spotlightContainerStack.leftAnchor.constraint(equalTo: spotlightBackground.leftAnchor, constant: 12).isActive = true
        spotlightContainerStack.bottomAnchor.constraint(equalTo: spotlightBackground.bottomAnchor, constant: -8).isActive = true

        impactStack.rightAnchor.constraint(equalTo: impactBackground.rightAnchor, constant: -16).isActive = true
        impactStack.topAnchor.constraint(equalTo: impactBackground.topAnchor, constant: 22).isActive = true
        impactStack.leftAnchor.constraint(equalTo: impactBackground.leftAnchor, constant: 16).isActive = true
        impactStack.bottomAnchor.constraint(equalTo: impactBackground.bottomAnchor, constant: -16).isActive = true

        spotlightClose.widthAnchor.constraint(equalToConstant: 16).isActive = true
    }

    func applyTheme() {
        let isSpotlight = model?.spotlight != nil
        if isSpotlight {
            background.backgroundColor = (isHighlighted || isSelected) ? .theme.ecosia.primaryBrand  : .theme.ecosia.teal60
        } else {
            background.backgroundColor = UIColor.theme.ecosia.primaryBackground
        }

        let backgroundColor: UIColor = model?.appearance == .ntp ? .theme.ecosia.ntpImpactBackground : .theme.ecosia.highlightedBackground
        impactBackground.backgroundColor = (isHighlighted || isSelected) ? .theme.ecosia.hoverBackgroundColor : backgroundColor

        spotlightBackground.backgroundColor = .clear

        globalCountDescription.textColor = .theme.ecosia.secondaryText
        globalCount.textColor = .theme.ecosia.primaryText

        yourImpact.textColor = .theme.ecosia.secondaryText
        treesPlanted.textColor = .theme.ecosia.primaryText

        spotlightHeadline.textColor = .white
        spotlightDescription.textColor = .white

        spotlightClose.tintColor = .white
    }

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }

    // MARK: Overrides
    override var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            applyTheme()
        }
        get {
            return super.isHighlighted
        }
    }

    override var isSelected: Bool {
        set {
            super.isSelected = newValue
            applyTheme()
        }
        get {
            return super.isSelected
        }
    }
}
