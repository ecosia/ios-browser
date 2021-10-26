/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class EmptyHeader: UITableViewHeaderFooterView, Themeable {
    required init?(coder: NSCoder) { nil }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    func applyTheme() {
        
//        view.backgroundColor = .theme.ecosia.modalBackground
//        subtitle?.textColor = .theme.ecosia.secondaryText
//        card?.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
//        card?.layer.borderColor = UIColor.theme.ecosia.impactMultiplyCardBorder.cgColor
//        cardIcon?.image = UIImage(themed: "impactReferrals")
//        cardTitle?.textColor = .theme.ecosia.highContrastText
//        cardSubtitle?.textColor = .theme.ecosia.secondaryText
//        flowTitle?.textColor = .theme.ecosia.secondaryText
//
//        dash?.applyTheme()
//        firstStep?.applyTheme()
//        secondStep?.applyTheme()
//        thirdStep?.applyTheme()
    }
}
