// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPImpactRowView: UIView, NotificationThemeable {
    
    private lazy var imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()
    private lazy var totalProgressView: ProgressView = {
        ProgressView(size: .init(width: 48, height: 30), lineWidth: 2)
    }()
    private lazy var currentProgressView: ProgressView = {
        ProgressView(size: .init(width: 48, height: 30), lineWidth: 2)
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
    
    var info: ClimateImpactInfo {
        didSet {
            imageView.image = info.image
            titleLabel.text = info.title
            subtitleLabel.text = info.subtitle
            actionButton.isHidden = info.buttonTitle == nil
            actionButton.setTitle(info.buttonTitle, for: .normal)
            // TODO: Add button action
            if let progress = info.progressIndicatorValue {
                currentProgressView.value = progress
            }
        }
    }
    var position: (row: Int, totalCount: Int) = (0, 0) {
        didSet {
            let (row, count) = position
            dividerView.isHidden = row == (count - 1)
            setMaskedCornersUsingPosition(row: row, totalCount: count)
        }
    }
    
    init(info: ClimateImpactInfo) {
        self.info = info
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 10
        
        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .fill
        hStack.spacing = 8
        hStack.addArrangedSubview(imageContainer)
        imageContainer.addSubview(imageView)
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
            imageContainer.widthAnchor.constraint(equalToConstant: 48),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor)
        ])
        
        if let progress = info.progressIndicatorValue {
            setupProgressIndicator()
        } else {
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            ])
        }
        
        applyTheme()
    }
    
    required init?(coder: NSCoder) { nil }
    
    func applyTheme() {
        backgroundColor = .theme.ecosia.secondaryBackground
        titleLabel.textColor = .theme.ecosia.primaryText
        subtitleLabel.textColor = .theme.ecosia.secondaryText
        actionButton.setTitleColor(.theme.ecosia.primaryButton, for: .normal)
        dividerView.backgroundColor = .theme.ecosia.border
        totalProgressView.color = .theme.ecosia.ntpBackground
        currentProgressView.color = .theme.ecosia.treeCounterProgressCurrent
    }
    
    private func setupProgressIndicator() {
        imageContainer.addSubview(totalProgressView)
        imageContainer.addSubview(currentProgressView)
        
        NSLayoutConstraint.activate([
            totalProgressView.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 4),
            totalProgressView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            currentProgressView.centerYAnchor.constraint(equalTo: totalProgressView.centerYAnchor),
            currentProgressView.centerXAnchor.constraint(equalTo: totalProgressView.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: totalProgressView.topAnchor, constant: 10),
            imageView.centerXAnchor.constraint(equalTo: totalProgressView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 26),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
    }
}
