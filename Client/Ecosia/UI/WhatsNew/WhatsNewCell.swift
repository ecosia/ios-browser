// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class WhatsNewCell: UITableViewCell {
    
    var contentConfigurationToUpdate: Any?
        
    func configure(with item: WhatsNewItem) {
        
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
    private func configureForiOS14(item: WhatsNewItem) {
        var newConfiguration = defaultContentConfiguration()
        newConfiguration.text = item.title
        newConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
        newConfiguration.textProperties.lineBreakMode = .byTruncatingTail
        newConfiguration.textProperties.adjustsFontForContentSizeCategory = true
        newConfiguration.textProperties.adjustsFontSizeToFitWidth = true
        newConfiguration.secondaryText = item.subtitle
        newConfiguration.secondaryTextProperties.lineBreakMode = .byTruncatingTail
        newConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        newConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        newConfiguration.secondaryTextProperties.adjustsFontSizeToFitWidth = true
        newConfiguration.image = item.image
        newConfiguration.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        contentConfiguration = newConfiguration
    }
    
    private func configureForiOS13(item: WhatsNewItem) {
        textLabel?.text = item.title
        textLabel?.lineBreakMode = .byTruncatingTail
        textLabel?.font = .preferredFont(forTextStyle: .headline)
        textLabel?.adjustsFontForContentSizeCategory = true
        textLabel?.adjustsFontSizeToFitWidth = true
        detailTextLabel?.text = item.subtitle
        detailTextLabel?.lineBreakMode = .byTruncatingTail
        detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailTextLabel?.adjustsFontForContentSizeCategory = true
        detailTextLabel?.adjustsFontSizeToFitWidth = true
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

extension WhatsNewCell: ReusableCell {}
