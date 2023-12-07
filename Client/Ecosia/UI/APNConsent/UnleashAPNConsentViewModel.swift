// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Core

final class UnleashAPNConsentViewModel: APNConsentViewModelProtocol {
    
    var title: String {
        titleMatchingVariant
    }
    
    var image: UIImage? {
        imageMatchinVariant
    }
        
    var listItems: [APNConsentListItem] {
        listItemsMatchingVariant
    }
}

extension UnleashAPNConsentViewModel {
    
    private var listItemsVariantNameControl: [APNConsentListItem] {
        [
            APNConsentListItem(title: .localized(.apnConsentVariantNameControlFirstItemTitle)),
            APNConsentListItem(title: .localized(.apnConsentVariantNameControlSecondItemTitle))
        ]
    }
    private var listItemsVariantNameTest1: [APNConsentListItem] {
        [
            APNConsentListItem(title: .localized(.apnConsentVariantNameTest1FirstItemTitle)),
            APNConsentListItem(title: .localized(.apnConsentVariantNameTest1SecondItemTitle))
        ]
    }
    
    private var listItemsMatchingVariant: [APNConsentListItem] {
        switch EngagementServiceExperiment.variantName {
        case "test1": return listItemsVariantNameTest1
        default: return listItemsVariantNameControl
        }
    }
    
    private var titleMatchingVariant: String {
        switch EngagementServiceExperiment.variantName {
        case "test1": return .localized(.apnConsentVariantNameTest1HeaderTitle)
        default: return .localized(.apnConsentVariantNameControlHeaderTitle)
        }
    }
    
    private var imageMatchinVariant: UIImage? {
        switch EngagementServiceExperiment.variantName {
        case "test1": return .init(named: "apnConsentImageTest1")
        default: return .init(named: "apnConsentImageControl")
        }
    }
}
