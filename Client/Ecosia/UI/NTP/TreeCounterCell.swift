/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class TreeCounterCell: UICollectionViewCell, Themeable {

    private let treeCounter = TreeCounter()
    private weak var descriptionLabel: UILabel!
    private weak var counter: UILabel!


    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let counter = UILabel()
        counter.translatesAutoresizingMaskIntoConstraints = false
        counter.textColor = UIColor.theme.ecosia.primaryBrand
        counter.font = .init(descriptor:
            UIFont.systemFont(ofSize: 24, weight: .medium).fontDescriptor.addingAttributes(
                [.featureSettings: [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                                     .typeIdentifier: kMonospacedNumbersSelector]]]), size: 0)
        contentView.addSubview(counter)
        self.counter = counter

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = .localized(.treesPlantedWithEcosia)
        descriptionLabel.textColor = UIColor.theme.ecosia.highContrastText
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        contentView.addSubview(descriptionLabel)
        self.descriptionLabel = descriptionLabel

        counter.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        counter.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true

        descriptionLabel.topAnchor.constraint(equalTo: counter.bottomAnchor, constant: 2).isActive = true
        descriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        descriptionLabel.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 20).isActive = true
        descriptionLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -20).isActive = true

        descriptionLabel.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor).isActive = true

        treeCounter.subscribe(self) { count in
            UIView.transition(with: counter, duration: 0.65, options: .transitionCrossDissolve, animations: {
                counter.text = formatter.string(from: .init(value: count))
            })
        }
        treeCounter.update(session: .shared) { _ in }
    }

    func applyTheme() {
        counter?.textColor = UIColor.theme.ecosia.primaryBrand
        descriptionLabel?.textColor = UIColor.theme.ecosia.highContrastText
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
