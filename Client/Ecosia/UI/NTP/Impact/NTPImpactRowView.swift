// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPImpactRowView: UIView, NotificationThemeable {
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title2).bold()
        return label
    }()
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()
    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        return button
    }()
    private lazy var dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var info: ClimateImpactInfo = .invites(value: 0) {
        didSet {
            imageView.image = info.image
            titleLabel.text = info.title
            subtitleLabel.text = info.subtitle
            actionButton.isHidden = info.buttonTitle == nil
            actionButton.setTitle(info.buttonTitle, for: .normal)
            // TODO: Add button action
        }
    }
    var position: (row: Int, totalCount: Int) = (0, 0) {
        didSet {
            let (row, count) = position
            dividerView.isHidden = row == (count - 1)
            setMaskedCornersUsingPosition(row: row, totalCount: count)
        }
    }
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        
        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .fill
        hStack.spacing = 8
        hStack.addArrangedSubview(imageView)
        addSubview(hStack)
        addSubview(dividerView)
        
        let vStack = UIStackView()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(subtitleLabel)
        hStack.addArrangedSubview(vStack)

        hStack.addArrangedSubview(actionButton)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 80),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            hStack.bottomAnchor.constraint(equalTo: dividerView.topAnchor, constant: -16),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
        
        applyTheme()
    }
    
    required init?(coder: NSCoder) { nil }
    
    func applyTheme() {
        backgroundColor = .theme.ecosia.secondaryBackground
        titleLabel.textColor = .theme.ecosia.primaryText
        subtitleLabel.textColor = .theme.ecosia.secondaryText
        actionButton.setTitleColor(.theme.ecosia.primaryButton, for: .normal)
        dividerView.backgroundColor = .theme.ecosia.border
    }
}
