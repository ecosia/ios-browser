/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit
import Storage
import Shared

class DefaultBrowserCard: UICollectionViewCell {
    public var dismissClosure: (() -> Void)?
    lazy var title: UILabel = {
        let title = UILabel()
        title.text = .localized(.makeEcosiaYourDefault)
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.font = .preferredFont(forTextStyle: .title3)
        title.adjustsFontForContentSizeCategory = true
        title.setContentHuggingPriority(.required, for: .vertical)
        return title
    }()
    lazy var descriptionText: UILabel = {
        let descriptionText = UILabel()
        descriptionText.text = .localized(.websitesWillAlwaysOpen)
        descriptionText.numberOfLines = 0
        descriptionText.font = .preferredFont(forTextStyle: .subheadline)
        descriptionText.adjustsFontForContentSizeCategory = true
        descriptionText.allowsDefaultTighteningForTruncation = true
        return descriptionText
    }()
    lazy var settingsButton: UIButton = {
        let button = UIButton()
        button.setTitle(String.DefaultBrowserCardButton, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    lazy var image: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "ecosiaIcon"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "nav-stop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        return closeButton
    }()
    lazy var background: UIView = {
        let background = UIView()
        background.layer.cornerRadius = 10
        return background
    }()
    weak var widthConstraint: NSLayoutConstraint!
    private var labelView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        background.addSubview(labelView)
        background.addSubview(image)
        background.addSubview(settingsButton)
        background.addSubview(closeButton)
        
        labelView.axis = .vertical
        labelView.alignment = .leading
        labelView.spacing = 4
        labelView.addArrangedSubview(title)
        labelView.addArrangedSubview(descriptionText)
        
        contentView.addSubview(background)
        
        setupConstraints()
        setupButtons()
        applyTheme()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        background.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(16)
        }
        
        image.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalTo(labelView.snp.left).offset(-16)
            make.height.width.equalTo(48).priority(.veryHigh)
            make.top.equalToSuperview().offset(24)
        }
        labelView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-36).priority(.veryHigh)
            make.bottom.equalTo(settingsButton.snp.top).offset(-16)
            make.top.equalToSuperview().offset(24)
        }
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(labelView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16).priority(.veryHigh)
            make.height.equalTo(44)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(image.snp.top)
            make.right.equalToSuperview().offset(-18)
            make.height.width.equalTo(16)
        }

        let widthConstraint = background.widthAnchor.constraint(equalToConstant: 200)
        widthConstraint.priority = .init(rawValue: 999)
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
    }
    
    private func setupButtons() {
        closeButton.addTarget(self, action: #selector(dismissCard), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
    }
    
    @objc private func dismissCard() {
        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard")
        Analytics.shared.defaultBrowser(.close)
        self.dismissClosure?()
    }
    
    @objc private func showSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
        Analytics.shared.defaultBrowser(.click)
    }
    
    func applyTheme() {
        background.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        title.textColor = UIColor.theme.ecosia.highContrastText
        descriptionText.textColor = UIColor.theme.ecosia.secondaryText
        closeButton.imageView?.tintColor = UIColor.theme.ecosia.highContrastText
        backgroundColor = UIColor.theme.ecosia.primaryBackground
        settingsButton.backgroundColor = UIColor.theme.ecosia.primaryButton
        applyShadow()
    }

    func applyShadow() {
        if !ThemeManager.instance.current.isDark {
            background.layer.shadowRadius = 3
            background.layer.shadowOffset = .init(width: 0, height: 1)
            background.layer.shadowColor = UIColor.black.cgColor
            background.layer.shadowOpacity = 0.15
        } else {
            background.layer.shadowOpacity = 0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
