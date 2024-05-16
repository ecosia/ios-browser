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

    private weak var logo: UIImageView!
    private weak var orgLogo: UIImageView!
    private weak var logoStack: UIStackView!

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
        logoStack.axis = .vertical
        logoStack.distribution = .fill
        logoStack.spacing = 12
        self.logoStack = logoStack
        
        let orgLogo = UIImageView(image: .init())
        orgLogo.translatesAutoresizingMaskIntoConstraints = false
        orgLogo.clipsToBounds = true
        orgLogo.contentMode = .scaleAspectFit
        orgLogo.heightAnchor.constraint(equalToConstant: 20).isActive = true
        self.orgLogo = orgLogo
        logoStack.addArrangedSubview(orgLogo)

        
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
        logoStack.widthAnchor.constraint(equalToConstant: Self.width).isActive = true
        applyTheme()
        listenForThemeChange(contentView)
    }

    func applyTheme() {
        logo.tintColor = .legacyTheme.ecosia.primaryBrand
        
        if let company = User.shared.company {
            let imageName = LegacyThemeManager.instance.current.isDark ? company.logoDark : company.logoLight
            let baseURL = Environment.current.urlProvider.companiesBase.absoluteString
            let finalURLString = baseURL + "/logos/" + imageName
            let finalUrl = URL(string: finalURLString)
            orgLogo.kf.setImage(with: finalUrl, options: [.processor(SVGImgProcessor())]) { result in
                debugPrint(result)
            }
        } else {
            orgLogo.image = nil
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
