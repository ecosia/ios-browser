// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPImpactRowView: UIView, NotificationThemeable {
    struct UX {
        static let height: CGFloat = 80
        static let cornerRadius: CGFloat = 10
        static let horizontalSpacing: CGFloat = 8
        static let padding: CGFloat = 16
        static let imageHeight: CGFloat = 48
        static let imageHeightWithProgress: CGFloat = 26
        static let progressWidth: CGFloat = 48
        static let progressHeight: CGFloat = 30
        static let progressLineWidth: CGFloat = 2
    }
    
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
        ProgressView(size: .init(width: UX.progressWidth, height: UX.progressHeight),
                     lineWidth: UX.progressLineWidth)
    }()
    private lazy var currentProgressView: ProgressView = {
        ProgressView(size: .init(width: UX.progressWidth, height: UX.progressHeight),
                     lineWidth: UX.progressLineWidth)
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
        layer.cornerRadius = UX.cornerRadius
        
        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .fill
        hStack.spacing = UX.horizontalSpacing
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
            heightAnchor.constraint(equalToConstant: UX.height),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding),
            hStack.bottomAnchor.constraint(equalTo: dividerView.topAnchor, constant: -UX.padding),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            imageContainer.heightAnchor.constraint(equalToConstant: UX.imageHeight),
            imageContainer.widthAnchor.constraint(equalTo: imageContainer.heightAnchor)
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
            imageView.heightAnchor.constraint(equalToConstant: UX.imageHeightWithProgress),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
    }
}
