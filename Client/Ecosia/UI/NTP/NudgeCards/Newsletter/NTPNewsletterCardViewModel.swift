// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class NTPNewsletterCardViewModel: NTPConfigurableNudgeCardCellViewModel {
    // TODO: Use localised strings once copy is final
    override var title: String {
        "Subscribe to our newsletter"
    }
    
    override var description: String {
        "Be the first to know about climate impact updates and exciting new features."
    }
    
    override var buttonText: String {
        "Subscribe now"
    }
    
    override var cardSectionType: HomepageSectionType {
        .newsletterCard
    }
    
    override var image: UIImage? {
        .init(named: "newsletterCardImage")
    }
    
    override var isEnabled: Bool {
        NewsletterCardExperiment.shouldShowCard
    }

    override func screenWasShown() {
        NewsletterCardExperiment.trackExperimentImpression()
    }
}
