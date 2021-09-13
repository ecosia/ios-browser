/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class MultiplayImpact: UIViewController, Themeable {
    private weak var subtitle: UILabel?
    private weak var card: UIView?
    private weak var cardIcon: UIImageView?
    private weak var cardTitle: UILabel?
    private weak var cardSubtitle: UILabel?
    private weak var flowTitle: UILabel?
    
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
        cardTitle.font = .preferredFont(forTextStyle: .subheadline)
        cardTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        card.addSubview(cardTitle)
        self.cardTitle = cardTitle
        
        let cardSubtitle = UILabel()
        cardSubtitle.translatesAutoresizingMaskIntoConstraints = false
        cardSubtitle.numberOfLines = 0
        cardSubtitle.text = .localizedPlural(.treesPlural, num: 5)
        cardSubtitle.font = .preferredFont(forTextStyle: .subheadline)
        cardSubtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        card.addSubview(cardSubtitle)
        self.cardSubtitle = cardSubtitle
        
        let learnMore = UIButton()
        learnMore.translatesAutoresizingMaskIntoConstraints = false
        learnMore.setTitle(.localized(.learnMore), for: .normal)
        learnMore.setTitleColor(.Photon.Teal50, for: .normal)
        learnMore.titleLabel!.font = .preferredFont(forTextStyle: .footnote)
        learnMore.addTarget(self, action: #selector(self.learnMore), for: .touchUpInside)
        card.addSubview(learnMore)
        
        let flowTitle = UILabel()
        flowTitle.translatesAutoresizingMaskIntoConstraints = false
        flowTitle.text = .localized(.invitingAFriend)
        flowTitle.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .semibold)
        scroll.addSubview(flowTitle)
        self.flowTitle = flowTitle
        
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
        card.bottomAnchor.constraint(greaterThanOrEqualTo: cardSubtitle.bottomAnchor, constant: 12).isActive = true
        
        cardIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 17).isActive = true
        cardIcon.leftAnchor.constraint(equalTo: card.leftAnchor, constant: 16).isActive = true
        
        cardTitle.topAnchor.constraint(equalTo: card.topAnchor, constant: 12).isActive = true
        cardTitle.leftAnchor.constraint(equalTo: cardIcon.rightAnchor, constant: 12).isActive = true
        cardTitle.rightAnchor.constraint(lessThanOrEqualTo: learnMore.leftAnchor, constant: -5).isActive = true
        
        cardSubtitle.topAnchor.constraint(equalTo: cardTitle.bottomAnchor).isActive = true
        cardSubtitle.leftAnchor.constraint(equalTo: cardIcon.rightAnchor, constant: 12).isActive = true
        cardSubtitle.rightAnchor.constraint(lessThanOrEqualTo: learnMore.leftAnchor, constant: -5).isActive = true
        
        learnMore.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
        learnMore.rightAnchor.constraint(equalTo: card.rightAnchor, constant: -16).isActive = true
        
        flowTitle.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 23).isActive = true
        flowTitle.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        
        let cardHeight = card.heightAnchor.constraint(equalToConstant: 0)
        cardHeight.priority = .defaultLow
        cardHeight.isActive = true
        
        applyTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }
    
    func applyTheme() {
        view.backgroundColor = .theme.ecosia.modalBackground
        subtitle?.textColor = .theme.ecosia.secondaryText
        card?.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
        card?.layer.borderColor = UIColor.theme.ecosia.impactMultiplyCardBorder.cgColor
        cardIcon?.image = UIImage(themed: "impactReferrals")
        cardTitle?.textColor = .theme.ecosia.highContrastText
        cardSubtitle?.textColor = .theme.ecosia.secondaryText
        flowTitle?.textColor = .theme.ecosia.secondaryText
    }
    
    @objc private func learnMore() {
        
    }
}
