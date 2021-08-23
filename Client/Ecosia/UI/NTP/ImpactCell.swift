/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

struct ImpactCellModel {
    var spotlight: Spotlight?
    let trees: Int

    struct Spotlight {
        let headline: String
        let description: String
    }
}

protocol ImpactCellDelegate: AnyObject {
    func impactCellDidTapSpotlight(_ cell: ImpactCell)
}

final class ImpactCell: UICollectionViewCell, Themeable {

    private (set) var model: ImpactCellModel?
    private let treeCounter = TreeCounter()
    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    weak var delegate: ImpactCellDelegate?

    private weak var background: UIView!
    private weak var container: UIStackView!

    private weak var spotlightBackground: UIView!
    private weak var spotlightStack: UIStackView!
    private weak var spotlightTopLine: UIStackView!
    private weak var spotlightHeadline: UILabel!
    private weak var spotlightDescription: UILabel!
    private weak var spotlightClose: UIImageView!

    private weak var impactBackground: UIView!
    private weak var impactStack: UIStackView!
    private weak var personalImpactStack: UIStackView!
    private weak var personalImpactLabelStack: UIStackView!
    private weak var treeImage: UIImageView!
    private weak var arrowImage: UIImageView!
    private weak var personalCountStack: UIStackView!
    private weak var personalCount: UILabel!
    private weak var impactOverviewLabel: UILabel!

    private weak var personalCountDescription: UILabel!

    private weak var globalCountBackground: UIView!
    private weak var globalCountStack: UIStackView!
    private weak var globalCount: UILabel!
    private weak var globalCountDescription: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
            guard let self = self else { return }

            UIView.transition(with: self.globalCount, duration: 0.65, options: .transitionCrossDissolve, animations: {
                self.globalCount.text = self.formatter.string(from: .init(value: count))
            })
        }
        treeCounter.update(session: .shared) { _ in }
    }

    func display(_ model: ImpactCellModel) {
        self.model = model

        personalCount.text = "\(model.trees)"
        spotlightViews.forEach { $0.isHidden = model.spotlight == nil }

        if let spotlight = model.spotlight {
            spotlightHeadline.text = spotlight.headline
            spotlightDescription.text = spotlight.description
        }
        applyTheme()
    }

    @objc func spotlightTapped() {
        delegate?.impactCellDidTapSpotlight(self)
    }

    var spotlightViews: [UIView] {
        return [spotlightBackground, spotlightStack]
    }

    // MARK: UI
    private func addSpotlight() {
        let spotlightBackground = UIView()
        spotlightBackground.translatesAutoresizingMaskIntoConstraints = false
        spotlightBackground.layer.cornerRadius = 8
        spotlightBackground.setContentHuggingPriority(.required, for: .vertical)
        container.addArrangedSubview(spotlightBackground)
        self.spotlightBackground = spotlightBackground

        spotlightBackground.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(spotlightTapped)))

        let spotlightStack = UIStackView()
        spotlightStack.axis = .vertical
        spotlightStack.translatesAutoresizingMaskIntoConstraints = false
        spotlightStack.spacing = 2
        spotlightBackground.addSubview(spotlightStack)
        self.spotlightStack = spotlightStack

        let spotlightTopLine = UIStackView()
        spotlightTopLine.axis = .horizontal
        spotlightStack.addArrangedSubview(spotlightTopLine)
        self.spotlightStack = spotlightStack

        let spotlightHeadline = UILabel()
        spotlightTopLine.addArrangedSubview(spotlightHeadline)
        spotlightHeadline.setContentCompressionResistancePriority(.required, for: .vertical)
        spotlightHeadline.font = .preferredFont(forTextStyle: .subheadline).bold()
        spotlightHeadline.adjustsFontForContentSizeCategory = true
        self.spotlightHeadline = spotlightHeadline

        let spotlightClose = UIImageView(image: .init(named: "close-medium")?.withRenderingMode(.alwaysTemplate))
        spotlightClose.contentMode = .scaleAspectFill
        spotlightTopLine.addArrangedSubview(spotlightClose)
        self.spotlightClose = spotlightClose

        let spotlightDescription = UILabel()
        spotlightDescription.numberOfLines = 2
        spotlightDescription.font = .preferredFont(forTextStyle: .subheadline)
        spotlightDescription.adjustsFontForContentSizeCategory = true
        spotlightDescription.setContentCompressionResistancePriority(.required, for: .vertical)
        spotlightStack.addArrangedSubview(spotlightDescription)
        self.spotlightDescription = spotlightDescription
    }

    private func addImpact() {
        let impactBackground = UIView()
        impactBackground.layer.borderWidth = 1
        impactBackground.setContentHuggingPriority(.defaultLow, for: .horizontal)
        impactBackground.translatesAutoresizingMaskIntoConstraints = false
        impactBackground.layer.cornerRadius = 8
        container.addArrangedSubview(impactBackground)
        self.impactBackground = impactBackground

        let impactStack = UIStackView()
        impactStack.axis = .vertical
        impactStack.spacing = 10
        impactStack.translatesAutoresizingMaskIntoConstraints = false
        impactBackground.addSubview(impactStack)
        self.impactStack = impactStack

        let personalImpactStack = UIStackView()
        personalImpactStack.axis = .horizontal
        personalImpactStack.spacing = 16
        personalImpactStack.translatesAutoresizingMaskIntoConstraints = false
        impactStack.addArrangedSubview(personalImpactStack)
        self.personalImpactStack = personalImpactStack

        let treeImage = UIImageView(image: .init(named: "personalCounter"))
        treeImage.translatesAutoresizingMaskIntoConstraints = false
        treeImage.contentMode = .scaleAspectFit
        treeImage.setContentHuggingPriority(.defaultLow, for: .horizontal)
        treeImage.setContentHuggingPriority(.defaultLow, for: .vertical)
        personalImpactStack.addArrangedSubview(treeImage)
        self.treeImage = treeImage

        let personalImpactLabelStack = UIStackView()
        personalImpactLabelStack.axis = .vertical
        personalImpactLabelStack.spacing = 2
        personalImpactLabelStack.translatesAutoresizingMaskIntoConstraints = false
        personalImpactStack.addArrangedSubview(personalImpactLabelStack)
        self.personalImpactLabelStack = personalImpactLabelStack

        let personalCountStack = UIStackView()
        personalCountStack.axis = .horizontal
        personalCountStack.spacing = 4
        personalCountStack.translatesAutoresizingMaskIntoConstraints = false
        personalImpactLabelStack.addArrangedSubview(personalCountStack)

        let personalCount = UILabel()
        personalCount.translatesAutoresizingMaskIntoConstraints = false
        personalCount.font = .preferredFont(forTextStyle: .headline)
        personalCount.adjustsFontForContentSizeCategory = true
        personalCount.setContentHuggingPriority(.required, for: .horizontal)
        personalCount.setContentHuggingPriority(.defaultLow, for: .vertical)
        personalCountStack.addArrangedSubview(personalCount)
        self.personalCount = personalCount

        let impactOverviewLabel = UILabel()
        impactOverviewLabel.text = .localized(.estimatedTrees)
        impactOverviewLabel.translatesAutoresizingMaskIntoConstraints = false
        impactOverviewLabel.font = .preferredFont(forTextStyle: .subheadline)
        impactOverviewLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        impactOverviewLabel.adjustsFontForContentSizeCategory = true
        personalImpactLabelStack.addArrangedSubview(impactOverviewLabel)
        self.impactOverviewLabel = impactOverviewLabel

        let arrowImage = UIImageView(image: .init(named: "forwardChevron")?.withRenderingMode(.alwaysTemplate))
        arrowImage.contentMode = .scaleAspectFit
        personalImpactStack.addArrangedSubview(arrowImage)
        self.arrowImage = arrowImage

        let globalCountBackground = UIView()
        globalCountBackground.translatesAutoresizingMaskIntoConstraints = false
        globalCountBackground.layer.cornerRadius = 8
        impactStack.addArrangedSubview(globalCountBackground)
        self.globalCountBackground = globalCountBackground

        let globalCountStack = UIStackView()
        globalCountStack.axis = .horizontal
        globalCountStack.distribution = .fillProportionally
        globalCountStack.spacing = 4
        globalCountStack.translatesAutoresizingMaskIntoConstraints = false
        globalCountBackground.addSubview(globalCountStack)
        self.globalCountStack = globalCountStack

        let globalCount = UILabel()
        globalCount.translatesAutoresizingMaskIntoConstraints = false
        globalCount.font = .preferredFont(forTextStyle: .subheadline).bold().monospace()
        globalCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        globalCount.setContentHuggingPriority(.defaultLow, for: .horizontal)
        globalCount.textAlignment = .right

        globalCountStack.addArrangedSubview(globalCount)
        self.globalCount = globalCount

        let globalCountDescription = UILabel()
        globalCountDescription.translatesAutoresizingMaskIntoConstraints = false
        globalCountDescription.text = .localized(.totalEcosiaTrees)
        globalCountDescription.font = .preferredFont(forTextStyle: .subheadline)
        globalCountDescription.adjustsFontForContentSizeCategory = true
        globalCountDescription.setContentHuggingPriority(.defaultLow, for: .horizontal)
        globalCountStack.addArrangedSubview(globalCountDescription)
        self.globalCountDescription = globalCountDescription
    }

    private func addConstraints() {
        // Constraints for stack views to their backgrounds
        background.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        background.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        background.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true

        container.rightAnchor.constraint(equalTo: background.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: background.topAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: background.leftAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: background.bottomAnchor).isActive = true

        spotlightStack.rightAnchor.constraint(equalTo: spotlightBackground.rightAnchor, constant: -12).isActive = true
        spotlightStack.topAnchor.constraint(equalTo: spotlightBackground.topAnchor, constant: 8).isActive = true
        spotlightStack.leftAnchor.constraint(equalTo: spotlightBackground.leftAnchor, constant: 12).isActive = true
        spotlightStack.bottomAnchor.constraint(equalTo: spotlightBackground.bottomAnchor, constant: -8).isActive = true

        impactStack.rightAnchor.constraint(equalTo: impactBackground.rightAnchor, constant: -16).isActive = true
        impactStack.topAnchor.constraint(equalTo: impactBackground.topAnchor, constant: 16).isActive = true
        impactStack.leftAnchor.constraint(equalTo: impactBackground.leftAnchor, constant: 16).isActive = true
        impactStack.bottomAnchor.constraint(equalTo: impactBackground.bottomAnchor, constant: -16).isActive = true

        globalCountStack.rightAnchor.constraint(equalTo: globalCountBackground.rightAnchor, constant: -8).isActive = true
        globalCountStack.topAnchor.constraint(equalTo: globalCountBackground.topAnchor, constant: 8).isActive = true
        globalCountStack.leftAnchor.constraint(equalTo: globalCountBackground.leftAnchor, constant: 8).isActive = true
        globalCountStack.bottomAnchor.constraint(equalTo: globalCountBackground.bottomAnchor, constant: -8).isActive = true

        treeImage.widthAnchor.constraint(equalToConstant: 30).isActive = true
        arrowImage.widthAnchor.constraint(equalToConstant: 8).isActive = true
    }

    func applyTheme() {
        let isSpotlight = model?.spotlight != nil
        if isSpotlight {
            background.backgroundColor = (isHighlighted || isSelected) ? UIColor.theme.ecosia.primaryBrand  : UIColor.Photon.Teal60
        } else {
            background.backgroundColor = UIColor.theme.ecosia.primaryBackground
        }

        spotlightBackground.backgroundColor = .clear
        impactBackground.backgroundColor = UIColor.theme.ecosia.primaryBackground
        globalCountBackground.backgroundColor = UIColor.theme.ecosia.treeCountBackground

        background.layer.borderColor = UIColor.theme.ecosia.personalCounterBorder.cgColor
        impactBackground.layer.borderColor = UIColor.theme.ecosia.personalCounterBorder.cgColor

        globalCountDescription.textColor = UIColor.theme.ecosia.treeCountText
        globalCount.textColor = UIColor.theme.ecosia.treeCountText
        personalCount.textColor = UIColor.theme.ecosia.highContrastText

        impactOverviewLabel.textColor = UIColor.theme.ecosia.secondaryText

        spotlightHeadline.textColor = .white
        spotlightDescription.textColor = .white

        spotlightClose.tintColor = .white
        arrowImage.tintColor = UIColor.theme.ecosia.secondaryText
    }

    // MARK: Overrides
    override func layoutSubviews() {
        super.layoutSubviews()
    }

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
