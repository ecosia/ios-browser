/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Common
import Kingfisher
import SVGKit

final class NTPLogoCell: UICollectionViewCell, ReusableCell, Themeable {
    static let bottomMargin: CGFloat = 6
    static let width: CGFloat = 144

    private var logo: UIImageView!
    private var orgLogo: UIImageView!
    private var logoStack: UIStackView!
    private var logoLabel: UILabel!

    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        
        let logoStack = UIStackView()
        logoStack.translatesAutoresizingMaskIntoConstraints = false
        logoStack.axis = .horizontal
        logoStack.distribution = .fill
        logoStack.spacing = 16
        self.logoStack = logoStack
                
        let orgLogo: UIImageView = .init()
        orgLogo.translatesAutoresizingMaskIntoConstraints = false
        orgLogo.clipsToBounds = true
        orgLogo.contentMode = .scaleAspectFit
        orgLogo.widthAnchor.constraint(lessThanOrEqualToConstant: 50).isActive = true
        self.orgLogo = orgLogo
        logoStack.addArrangedSubview(orgLogo)

        let logoLabel = UILabel()
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.text = "&"
        logoLabel.textAlignment = .center
        logoLabel.font = .preferredFont(forTextStyle: .headline)
        logoLabel.adjustsFontForContentSizeCategory = true
        logoStack.addArrangedSubview(logoLabel)
        self.logoLabel = logoLabel

        let logo = UIImageView(image: .init(named: "ecosiaLogoLaunch")?.withRenderingMode(.alwaysTemplate))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .scaleAspectFit
        logo.isAccessibilityElement = true
        logo.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.logo
        logo.accessibilityLabel = .localized(.ecosiaLogoAccessibilityLabel)
        self.logo = logo
        logoStack.addArrangedSubview(logo)
                
        contentView.addSubview(logoStack)

        let bottom = logoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.bottomMargin)
        bottom.priority = .defaultHigh
        bottom.isActive = true

        logoStack.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        logoStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        logoStack.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.width).isActive = true
        logoStack.heightAnchor.constraint(lessThanOrEqualToConstant: 50).isActive = true
        applyTheme()
        listenForThemeChange(contentView)
    }

    func applyTheme() {
        logo.tintColor = .legacyTheme.ecosia.primaryBrand
        logoLabel.textColor = .legacyTheme.ecosia.secondaryText
        
        if let company = User.shared.company {
            let imageName = LegacyThemeManager.instance.current.isDark ? company.logoDark : company.logoLight
            let baseURL = Environment.current.urlProvider.companiesBase.absoluteString
            let finalURLString = baseURL + "/logos/" + imageName
            let finalUrl = URL(string: finalURLString)
            logoLabel.isHidden = false
            orgLogo.isHidden = false
            orgLogo.kf.setImage(with: finalUrl, 
                                options: [.processor(SVGImgProcessor())])
        } else {
            orgLogo.image = nil
            orgLogo.isHidden = true
            logoLabel.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}

public struct SVGImgProcessor:ImageProcessor {
    public var identifier: String = "com.appidentifier.webpprocessor"
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            print("already an image")
            return image
        case .data(let data):
            let imsvg = SVGKImage(data: data)
            return imsvg?.uiImage
        }
    }
}
