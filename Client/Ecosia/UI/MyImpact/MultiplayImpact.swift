/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplayImpact: UIViewController, Themeable {
    private weak var subtitle: UILabel?
    private weak var card: UIView?
    private weak var cardTitle: UILabel?
    private weak var cardIcon: UIImageView?
    
    required init?(coder: NSCoder) { nil }
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = .localized(.sharingEcosia)
        
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.numberOfLines = 0
        subtitle.text = .localized(.everyTimeYouInvite)
        self.subtitle = subtitle
        
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        scroll.addSubview(subtitle)
        
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = false
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 1
        scroll.addSubview(card)
        self.card = card
        
        let cardIcon = UIImageView()
        cardIcon.translatesAutoresizingMaskIntoConstraints = false
        cardIcon.clipsToBounds = true
        cardIcon.contentMode = .center
        card.addSubview(cardIcon)
        self.cardIcon = cardIcon
        
        let cardTitle = UILabel()
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        cardTitle.numberOfLines = 0
        cardTitle.text = .localized(.invite3Friends)
        cardTitle.font = .preferredFont(forTextStyle: .body)
        cardTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        card.addSubview(cardTitle)
        self.cardTitle = cardTitle
        
        scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        scroll.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        
        subtitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        subtitle.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        subtitle.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        
        card.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 16).isActive = true
        card.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        card.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        card.bottomAnchor.constraint(greaterThanOrEqualTo: cardIcon.bottomAnchor, constant: 17).isActive = true
        
        cardIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 17).isActive = true
        cardIcon.leftAnchor.constraint(equalTo: card.leftAnchor, constant: 16).isActive = true
        
        applyTheme()
    }
    
    func applyTheme() {
        view.backgroundColor = .theme.ecosia.modalBackground
        subtitle?.textColor = .theme.ecosia.secondaryText
        card?.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
        cardTitle?.textColor = .theme.ecosia.secondaryText
        card?.layer.borderColor = UIColor.theme.ecosia.impactMultiplyCardBorder.cgColor
        cardIcon?.image = UIImage(themed: "impactReferrals")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }
}
