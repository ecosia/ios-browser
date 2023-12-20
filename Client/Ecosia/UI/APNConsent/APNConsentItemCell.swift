// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class APNConsentItemCell: UITableViewCell {
    
    private var item: APNConsentListItem!
    private var contentConfigurationToUpdate: Any?
            
    func configure(with item: APNConsentListItem) {        
        selectionStyle = .none
        backgroundColor = .clear
        self.item = item
        configureBasedOnOSVersion()
        applyTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
    }
    
    private func configureBasedOnOSVersion() {
        if #available(iOS 14, *) {
            configureForiOS14(item: item)
        } else {
            configureForiOS13(item: item)
        }
    }
    
    @available(iOS 14, *)
    private func configureForiOS14(item: APNConsentListItem) {
        var newConfiguration = defaultContentConfiguration()
        newConfiguration.text = item.title
        newConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
        newConfiguration.textProperties.lineBreakMode = .byTruncatingTail
        newConfiguration.textProperties.adjustsFontForContentSizeCategory = true
        newConfiguration.textProperties.adjustsFontSizeToFitWidth = true
        newConfiguration.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        contentConfigurationToUpdate = newConfiguration
    }
    
    private func configureForiOS13(item: APNConsentListItem) {
        textLabel?.text = item.title
        textLabel?.lineBreakMode = .byTruncatingTail
        textLabel?.font = .preferredFont(forTextStyle: .body)
        textLabel?.adjustsFontForContentSizeCategory = true
        textLabel?.adjustsFontSizeToFitWidth = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if #available(iOS 14, *) {
            var newConfiguration = defaultContentConfiguration()
            newConfiguration.text = nil
            newConfiguration.image = nil
        } else {
            textLabel?.text = nil
            imageView?.image = nil
        }
    }
}

extension APNConsentItemCell: NotificationThemeable {
    
    @objc func applyTheme() {
        if #available(iOS 14, *) {
            guard var updatedConfiguration = contentConfigurationToUpdate as? UIListContentConfiguration else { return }
            updatedConfiguration.textProperties.color = .theme.ecosia.secondaryText
            updatedConfiguration.image = item.image
            contentConfiguration = updatedConfiguration
        } else {
            textLabel?.textColor = .theme.ecosia.secondaryText
            imageView?.image = item.image
        }
    }
}

extension APNConsentItemCell: ReusableCell {}
