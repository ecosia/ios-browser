// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class WhatsNewCell: UITableViewCell {
    
    var contentConfigurationToUpdate: Any?
    private var imageURL: URL?
        
    func configure(with item: WhatsNewItem, images: Images) {
        
        selectionStyle = .none
        backgroundColor = .clear
        
        guard let itemImageURL = item.imageURL else { return }
        imageURL = itemImageURL

        // Load the image asynchronously
        images.load(self, url: itemImageURL) { [weak self] imageData in
            guard let self = self else { return }
            guard self.imageURL == imageData.url else { return }
            let image = UIImage(data: imageData.data)

            // Configure based on iOS version
            if #available(iOS 14, *) {
                self.configureForiOS14(image: image, item: item)
            } else {
                self.configureForiOS13(image: image, item: item)
            }
        }
    }
    
    @available(iOS 14, *)
    private func configureForiOS14(image: UIImage?, item: WhatsNewItem) {
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
        newConfiguration.image = image
        newConfiguration.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        contentConfiguration = newConfiguration
    }
    
    private func configureForiOS13(image: UIImage?, item: WhatsNewItem) {
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
        imageView?.image = image
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