// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class PageActionMenuCell: UITableViewCell {
    
    private weak var badge: UIView?
    private weak var badgeLabel: UILabel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isNew(_ isNew: Bool) {
        if isNew {
            if badge == nil {
                let badge = UIView()
                badge.isUserInteractionEnabled = false
                accessoryView = badge
                
                let badgeLabel = UILabel()
                badgeLabel.translatesAutoresizingMaskIntoConstraints = false
                badgeLabel.font = .preferredFont(forTextStyle: .footnote).bold()
                badgeLabel.adjustsFontForContentSizeCategory = true
                badgeLabel.text = .localized(.new)
                badge.addSubview(badgeLabel)
                
                badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 2.5).isActive = true
                badgeLabel.leftAnchor.constraint(equalTo: badge.leftAnchor, constant: 8).isActive = true
                
                self.badge = badge
                self.badgeLabel = badgeLabel
            }
            
            let size = badgeLabel?.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)) ?? .zero
            let height = size.height + 5
            badge?.layer.cornerRadius = height / 2
            badge?.frame.size = .init(width: size.width + 16, height: height)
            badge?.backgroundColor = .theme.ecosia.primaryBrand
            badgeLabel?.textColor = .theme.ecosia.primaryTextInverted
        } else {
            accessoryView = nil
        }
    }
}
