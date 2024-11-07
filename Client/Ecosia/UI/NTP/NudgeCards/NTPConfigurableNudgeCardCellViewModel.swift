// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Delegate that forwards events to the Cell to let perform its appropriate actions.
/// The `cardType` corresponds to the section type we will always need to define for each card.
protocol NTPConfigurableNudgeCardCellDelegate: AnyObject {
    func nudgeCardRequestToDimiss(for cardType: HomepageSectionType)
    func nudgeCardRequestToPerformAction(for cardType: HomepageSectionType)
}

/// ViewModel for configuring a Nudge Card Cell.
class NTPConfigurableNudgeCardCellViewModel: HomepageViewModelProtocol {
    
    var title: String
    var description: String
    var buttonText: String
    var image: UIImage?
    var showsCloseButton: Bool
    var cardSectionType: HomepageSectionType
    var identifier: String?
    var theme: Theme
    weak var delegate: NTPConfigurableNudgeCardCellDelegate?
    
    /// Initializes the ViewModel with the required properties to configure a card.
    /// - Parameters:
    ///   - title: Title text for the card.
    ///   - description: Description text for the card.
    ///   - buttonText: Text to display on the action button.
    ///   - image: Optional image to display on the card.
    ///   - showsCloseButton: Boolean to show or hide the close button.
    ///   - cardType: The associated `HomepageSectionType` for a given card. Used by the NTP to make each card a single section.
    ///   - identifier: Optional unique identifier for the card.
    ///   - theme: The current theme for styling the card.
    init(title: String,
         description: String,
         buttonText: String,
         image: UIImage? = nil,
         showsCloseButton: Bool = true,
         cardType: HomepageSectionType,
         identifier: String? = nil,
         theme: Theme) {
        
        self.title = title
        self.description = description
        self.buttonText = buttonText
        self.image = image
        self.showsCloseButton = showsCloseButton
        self.cardSectionType = cardType
        self.theme = theme
        self.identifier = identifier ?? sectionType.cellIdentifier
    }
    
    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var sectionType: HomepageSectionType {
        cardSectionType
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(200))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(200))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, topSpacing: 24)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        fatalError("Needs to be implemented")
    }
    
    func screenWasShown() {
        fatalError("Needs to be implemented. Implement empty if not needed")
    }
}

extension NTPConfigurableNudgeCardCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        (cell as? NTPConfigurableNudgeCardCell)?.configure(with: self)
        return cell
    }
}
