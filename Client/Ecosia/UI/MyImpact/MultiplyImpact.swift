/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class MultiplyImpact: UIViewController, Themeable {
    private weak var subtitle: UILabel?
    private weak var card: UIControl?
    private weak var cardIcon: UIImageView?
    private weak var cardTitle: UILabel?
    private weak var cardSubtitle: UILabel?
    private weak var flowTitle: UILabel?
    private weak var inviteButton: UIButton!
    private weak var dash: MultiplyImpactDash?
    private weak var firstStep: MultiplyImpactStep?
    private weak var secondStep: MultiplyImpactStep?
    private weak var thirdStep: MultiplyImpactStep?
    private weak var delegate: EcosiaHomeDelegate?
    private weak var referrals: Referrals!
    
    required init?(coder: NSCoder) { nil }
    init(delegate: EcosiaHomeDelegate?, referrals: Referrals) {
        self.referrals = referrals
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = .localized(.inviteFriends)
        
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.numberOfLines = 0
        subtitle.text = .localized(.everyTimeYouInvite)
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitle.adjustsFontForContentSizeCategory = true
        content.addSubview(subtitle)
        self.subtitle = subtitle
        
        let card = UIControl()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 1
        card.addTarget(self, action: #selector(highlight), for: .touchDown)
        card.addTarget(self, action: #selector(clear), for: .touchUpInside)
        card.addTarget(self, action: #selector(clear), for: .touchUpOutside)
        card.addTarget(self, action: #selector(clear), for: .touchCancel)
        card.addTarget(self, action: #selector(self.learnMore), for: .touchUpInside)
        content.addSubview(card)
        self.card = card
        
        let cardIcon = UIImageView()
        cardIcon.translatesAutoresizingMaskIntoConstraints = false
        cardIcon.contentMode = .center
        card.addSubview(cardIcon)
        self.cardIcon = cardIcon
        
        let cardTitle = UILabel()
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        cardTitle.numberOfLines = 0
        cardTitle.text = .localizedPlural(.successfulInvites, num: User.shared.referrals.count)
        cardTitle.font = .preferredFont(forTextStyle: .subheadline)
        cardTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cardTitle.adjustsFontForContentSizeCategory = true
        card.addSubview(cardTitle)
        self.cardTitle = cardTitle
        
        let cardSubtitle = UILabel()
        cardSubtitle.translatesAutoresizingMaskIntoConstraints = false
        cardSubtitle.numberOfLines = 0
        cardSubtitle.text = .localizedPlural(.treesPlural, num: User.shared.referrals.count)
        cardSubtitle.font = .preferredFont(forTextStyle: .subheadline)
        cardSubtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cardSubtitle.setContentCompressionResistancePriority(.required, for: .vertical)
        cardSubtitle.adjustsFontForContentSizeCategory = true
        card.addSubview(cardSubtitle)
        self.cardSubtitle = cardSubtitle
        
        let learnMore = UILabel()
        learnMore.translatesAutoresizingMaskIntoConstraints = false
        learnMore.text = .localized(.learnMore)
        learnMore.textColor = .theme.ecosia.primaryBrand
        learnMore.font = .preferredFont(forTextStyle: .callout)
        learnMore.adjustsFontForContentSizeCategory = true
        card.addSubview(learnMore)
        
        let flowTitle = UILabel()
        flowTitle.translatesAutoresizingMaskIntoConstraints = false
        flowTitle.text = .localized(.invitingAFriend)
        flowTitle.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .semibold)
        flowTitle.adjustsFontForContentSizeCategory = true
        content.addSubview(flowTitle)
        self.flowTitle = flowTitle
        
        let dash = MultiplyImpactDash()
        content.addSubview(dash)
        self.dash = dash
        
        let firstStep = MultiplyImpactStep(title: .localized(.shareYourInvitation), subtitle: .localized(.viaEmailText))
        content.addSubview(firstStep)
        self.firstStep = firstStep
        
        let secondStep = MultiplyImpactStep(title: .localized(.yourFriendOpens), subtitle: .localized(.afterInstallingTheApp))
        content.addSubview(secondStep)
        self.secondStep = secondStep
        
        let thirdStep = MultiplyImpactStep(title: .localized(.eachOfYouContribute), subtitle: .localized(.forEverySuccessful))
        content.addSubview(thirdStep)
        self.thirdStep = thirdStep
        
        let inviteFriends = UIButton()
        inviteFriends.translatesAutoresizingMaskIntoConstraints = false
        inviteFriends.setTitle(.localized(.inviteFriends), for: [])
        inviteFriends.setTitleColor(.white, for: .normal)
        inviteFriends.setTitleColor(.white.withAlphaComponent(0.3), for: .highlighted)
        inviteFriends.titleLabel!.font = .preferredFont(forTextStyle: .callout)
        inviteFriends.titleLabel!.adjustsFontForContentSizeCategory = true
        inviteFriends.layer.cornerRadius = 10
        inviteFriends.backgroundColor = UIColor(named: "primaryBrand")!
        inviteFriends.addTarget(self, action: #selector(self.inviteFriends), for: .touchUpInside)
        content.addSubview(inviteFriends)
        self.inviteButton = inviteFriends
        
        scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scroll.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        content.topAnchor.constraint(equalTo: scroll.topAnchor).isActive = true
        content.leftAnchor.constraint(equalTo: scroll.leftAnchor).isActive = true
        content.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        content.rightAnchor.constraint(equalTo: scroll.rightAnchor).isActive = true
        content.bottomAnchor.constraint(greaterThanOrEqualTo: scroll.bottomAnchor).isActive = true
        content.bottomAnchor.constraint(equalTo: inviteFriends.bottomAnchor, constant: 16).isActive = true
        
        subtitle.topAnchor.constraint(equalTo: content.topAnchor, constant: 8).isActive = true
        subtitle.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        subtitle.rightAnchor.constraint(lessThanOrEqualTo: content.rightAnchor, constant: -16).isActive = true
        
        card.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 16).isActive = true
        card.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        card.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -16).isActive = true
        card.bottomAnchor.constraint(greaterThanOrEqualTo: cardIcon.bottomAnchor, constant: 17).isActive = true
        card.bottomAnchor.constraint(greaterThanOrEqualTo: cardSubtitle.bottomAnchor, constant: 12).isActive = true
        
        cardIcon.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 17).isActive = true
        cardIcon.leftAnchor.constraint(equalTo: card.leftAnchor, constant: 16).isActive = true
        cardIcon.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
        
        cardTitle.topAnchor.constraint(equalTo: card.topAnchor, constant: 12).isActive = true
        cardTitle.leftAnchor.constraint(equalTo: cardIcon.rightAnchor, constant: 12).isActive = true
        cardTitle.rightAnchor.constraint(lessThanOrEqualTo: learnMore.leftAnchor, constant: -5).isActive = true
        
        cardSubtitle.topAnchor.constraint(equalTo: cardTitle.bottomAnchor).isActive = true
        cardSubtitle.leftAnchor.constraint(equalTo: cardIcon.rightAnchor, constant: 12).isActive = true
        cardSubtitle.rightAnchor.constraint(lessThanOrEqualTo: learnMore.leftAnchor, constant: -5).isActive = true
        
        learnMore.centerYAnchor.constraint(equalTo: card.centerYAnchor).isActive = true
        learnMore.rightAnchor.constraint(equalTo: card.rightAnchor, constant: -16).isActive = true
        
        flowTitle.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 23).isActive = true
        flowTitle.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        
        dash.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        dash.topAnchor.constraint(equalTo: firstStep.topAnchor, constant: 17).isActive = true
        dash.bottomAnchor.constraint(equalTo: thirdStep.topAnchor, constant: 5).isActive = true
        dash.widthAnchor.constraint(equalToConstant: 12).isActive = true
        
        firstStep.topAnchor.constraint(equalTo: flowTitle.bottomAnchor, constant: 12).isActive = true
        firstStep.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        firstStep.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        
        secondStep.topAnchor.constraint(equalTo: firstStep.bottomAnchor, constant: 20).isActive = true
        secondStep.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        secondStep.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        
        thirdStep.topAnchor.constraint(equalTo: secondStep.bottomAnchor, constant: 20).isActive = true
        thirdStep.leftAnchor.constraint(equalTo: content.leftAnchor).isActive = true
        thirdStep.rightAnchor.constraint(equalTo: content.rightAnchor).isActive = true
        
        inviteFriends.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        inviteFriends.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -16).isActive = true
        inviteFriends.heightAnchor.constraint(equalToConstant: 44).isActive = true
        inviteFriends.topAnchor.constraint(greaterThanOrEqualTo: thirdStep.bottomAnchor, constant: 16).isActive = true
        
        let contentHeight = content.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor)
        contentHeight.priority = .defaultLow
        contentHeight.isActive = true
        
        let cardHeight = card.heightAnchor.constraint(equalToConstant: 0)
        cardHeight.priority = .defaultHigh
        cardHeight.isActive = true
        
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.shared.openInvitations()
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
        
        dash?.applyTheme()
        firstStep?.applyTheme()
        secondStep?.applyTheme()
        thirdStep?.applyTheme()
    }
    
    @objc private func learnMore() {
        delegate?.ecosiaHome(didSelectURL: URL(string: "https://ecosia.zendesk.com/hc/en-us/articles/4406431901714-How-does-inviting-friends-to-Ecosia-work-")!)
        clear()
        dismiss(animated: true)
    }
    
    @objc private func inviteFriends() {
        guard let message = inviteMessage else {
            referrals.refresh { error in
                if let error = error {
                    self.showReferralError(error)
                } else {
                    self.share(message: self.inviteMessage!)
                }
            }
            return
        }
        share(message: message)
    }

    private func share(message: String) {
        let share = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = inviteButton
        share.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                Analytics.shared.sendInvite()
            }
        }
        present(share, animated: true)

        Analytics.shared.startInvite()
    }

    private func showReferralError(_ error: Referrals.Error) {
        let alert = UIAlertController(title: error.title,
                                      message: error.message,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .cancel))
        alert.addAction(.init(title: .localized(.retryMessage), style: .default) { [weak self] _ in
            self?.inviteFriends()
        })
        present(alert, animated: true)
    }

    @objc private func highlight() {
        card?.backgroundColor = .theme.ecosia.hoverBackgroundColor
    }
    
    @objc private func clear() {
        card?.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
    }
    
    private var inviteMessage: String? {
        guard let link = inviteLink else { return nil }
        
        return """
🌳🔗 \(String.localized(.heyThereWantToPlant))

\(String.localized(.downloadEcosiaOn))
https://apps.apple.com/app/apple-store/id670881887?pt=2188920&ct=referrals&mt=8

\(String.localized(.clickMyInvitation))
\(link)

\(String.localized(.letsDoThis)) 😊
"""
    }
    
    private var inviteLink: String? {
        guard let code = User.shared.referrals.code else { return nil }
        return "ecosia://invite/" + code
    }
}
