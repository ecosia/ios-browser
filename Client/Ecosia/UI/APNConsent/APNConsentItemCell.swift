// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class APNConsentItemCell: UITableViewCell {
    
    var contentConfigurationToUpdate: Any?
        
    func configure(with item: APNConsentListItem) {
        
        selectionStyle = .none
        backgroundColor = .clear
        
        // Configure based on iOS version
        if #available(iOS 14, *) {
            self.configureForiOS14(item: item)
        } else {
            self.configureForiOS13(item: item)
        }
    }
    
    @available(iOS 14, *)
    private func configureForiOS14(item: APNConsentListItem) {
        var newConfiguration = defaultContentConfiguration()
        newConfiguration.text = item.title
        newConfiguration.textProperties.color = .theme.ecosia.secondaryText
        newConfiguration.textProperties.font = .preferredFont(forTextStyle: .body)
        newConfiguration.textProperties.lineBreakMode = .byTruncatingTail
        newConfiguration.textProperties.adjustsFontForContentSizeCategory = true
        newConfiguration.textProperties.adjustsFontSizeToFitWidth = true
        newConfiguration.image = item.image
        newConfiguration.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        contentConfiguration = newConfiguration
    }
    
    private func configureForiOS13(item: APNConsentListItem) {
        textLabel?.text = item.title
        textLabel?.textColor = .theme.ecosia.secondaryText
        textLabel?.lineBreakMode = .byTruncatingTail
        textLabel?.font = .preferredFont(forTextStyle: .body)
        textLabel?.adjustsFontForContentSizeCategory = true
        textLabel?.adjustsFontSizeToFitWidth = true
        imageView?.image = item.image
    }

    @available(iOS 14.0, *)
    override func updateConfiguration(using state: UICellConfigurationState) {
        // Don't update the contentConfiguration based on the cell's state
        // If you have a saved configuration, apply it here
        if let updatedConfiguration = (contentConfigurationToUpdate as? UIListContentConfiguration) {
            contentConfiguration = updatedConfiguration
        }
    }
}

extension APNConsentItemCell: ReusableCell {}
