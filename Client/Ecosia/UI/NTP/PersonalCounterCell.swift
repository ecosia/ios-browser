/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class PersonalCounterCell: UICollectionViewCell, Themeable {

    private let personalCounter = PersonalCounter()
    private weak var stack: UIStackView!
    private weak var background: UIView!
    private weak var image: UIImageView!
    private weak var counterLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {

        let background = UIView()
        background.layer.borderWidth = 1
        background.setContentHuggingPriority(.defaultLow, for: .horizontal)
        background.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(background)
        self.background = background

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 2
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.backgroundColor = .clear
        contentView.addSubview(stack)
        self.stack = stack

        let image = UIImageView(image: .init(named: "personalCounter"))
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        image.setContentHuggingPriority(.required, for: .horizontal)
        image.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(image)
        self.image = image

        let counterLabel = UILabel()
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        counterLabel.textColor = UIColor.theme.ecosia.highContrastText
        counterLabel.font = .preferredFont(forTextStyle: .caption2)
        counterLabel.adjustsFontForContentSizeCategory = true
        counterLabel.setContentHuggingPriority(.required, for: .horizontal)
        counterLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        stack.addArrangedSubview(counterLabel)
        self.counterLabel = counterLabel

        background.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        background.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        background.leftAnchor.constraint(equalTo: stack.leftAnchor, constant: -16).isActive = true

        stack.rightAnchor.constraint(equalTo: background.rightAnchor, constant: -16).isActive = true
        stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        image.widthAnchor.constraint(equalTo: image.heightAnchor).isActive = true

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        personalCounter.subscribeAndReceive(self) { count in
            counterLabel.text = formatter.string(from: .init(value: count))
        }

        applyTheme()
    }

    func applyTheme() {
        background.backgroundColor = (isHighlighted || isSelected) ? UIColor.theme.ecosia.personalCounterSelection  : UIColor.theme.ecosia.primaryBackground

        background.layer.borderColor = UIColor.theme.ecosia.personalCounterBorder.cgColor
        counterLabel?.textColor = UIColor.theme.ecosia.highContrastText
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        background.layer.cornerRadius = (bounds.height - 32) / 2.0
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
