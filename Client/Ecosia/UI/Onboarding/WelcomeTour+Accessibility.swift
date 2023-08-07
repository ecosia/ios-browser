// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension WelcomeTour {
    /// Accessibility Strings for Onboarding texts that are NOT localized
    enum Accessibility: String {
        case pageControlDots = "Page control dots"
        case backButton = "Back"
        case skipTourButton = "Skip the onboarding"
        case continueCTAButton = "Continue to the next onboarding page"
        case finishCTAButton = "Finish onbaording and start contributing to Ecosia"
        case illustrationTour1 = "This onboarding illustration shows how by performing searches via the Ecosia app, you are leveling up your tree planting impact score. A small search screenshot and a smaller Your Impact section is shown. Leaves on the background."
        case illustrationTour1Alternative = "This onboarding illustration shows how by performing searches via the Ecosia app, you are leveling up your planed-friendly lifestyle. A small search input field screenshot and result example containing the green icon is shown. A forest can be seen on the background."
        case illustrationTour2 = "This onboarding illustration shows briefly an example of a before and after comparision of trees planted in a land. The image is a screenshot from the satellite view."
        case illustrationTour3 = "This onboarding illustration shows a few numbers like the projects Ecosia is involved in, the total number of trees planted by the Ecosia community, alongisde the number of countries Ecosia is active. A small map of the planisphere with trees pins in few geographic location, background."
        case illustrationTour4 = "This onboarding illustration is a photo of a monkey climbing a tree. It function mainly as general decoration image."
        case illustrationTour4Alternative = "This onboarding illustration shows the latest financial reports of Ecosia. On the background there is an image of a person caring for tree seedlings"
    }
}
