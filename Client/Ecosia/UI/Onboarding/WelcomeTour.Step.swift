/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

extension WelcomeTour {

    final class Step {
        let title: String
        let text: String
        let background: Background
        let content: UIView?

        init(title: String, text: String, background: Background, content: UIView?, accessibleDescription: Accessibility) {
            self.title = title
            self.text = text
            self.background = background
            content?.isAccessibilityElement = true
            content?.accessibilityLabel = accessibleDescription.rawValue
            self.content = content
        }

        static var planet: Step {
            return .init(title: .localized(.aBetterPlanet), text: .localized(.searchTheWeb), background: .init(image: "tour1"), content: WelcomeTourPlanet(), accessibleDescription: .illustrationTour1)
        }
        
        static var green: Step {
            return .init(title: .localized(.grennestWayToSearch), text: .localized(.planetFriendlySearch), background: .init(image: "tour1-alternative"), content: WelcomeTourGreen(), accessibleDescription: .illustrationTour1Alternative)
        }

        static var profit: Step {
            return .init(title: .localized(.hundredPercentOfProfits), text: .localized(.weUseAllOurProfits), background: .init(image: "tour2"), content: WelcomeTourProfit(), accessibleDescription: .illustrationTour2)
        }

        static var action: Step {
            return .init(title: .localized(.collectiveAction), text: .localized(.join15Million), background: .init(image: "tour3", color: UIColor(rgb: 0x668A7A)), content: WelcomeTourAction(), accessibleDescription: .illustrationTour3)
        }

        static var trees: Step {
            return .init(title: .localized(.weWantTrees), text: .localized(.weDontCreateAProfile), background: .init(image: "tour4"), content: nil, accessibleDescription: .illustrationTour4)
        }
        
        static var transparent: Step {
            return .init(title: .localized(.realResults), text: .localized(.shownExactlyHowMuch), background: .init(image: "tour4-alternative"), content: WelcomeTourTransparent(), accessibleDescription: .illustrationTour4Alternative)
        }

        static var all: [Step] {
            if IncentivizedSearchHelper.isRestricted {
                return [green, profit, action, transparent]
            } else {
                return [planet, profit, action, trees]
            }
            
        }
    }
}

extension WelcomeTour.Step {

    final class Background {
        let image: String
        let color: UIColor?

        init(image: String, color: UIColor? = nil) {
            self.image = image
            self.color = color
        }
    }
}
