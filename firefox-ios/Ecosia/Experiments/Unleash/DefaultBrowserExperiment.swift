// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct DefaultBrowserExperiment {
    private enum Variant: String {
        case control
        case a
        case b
        case c
    }

    private init() {}

    public static var isEnabled: Bool {
        Unleash.isEnabled(.defaultBrowser)
    }

    private static var variant: Variant {
        Variant(rawValue: Unleash.getVariant(.defaultBrowser).name) ?? .control
    }

    public static var title: String {
        switch variant {
        case .control:
            return .localized(.makeEcosiaYourDefaultBrowser)
        case .a:
            return .localized(.defaultBrowserPromptExperimentTitleVarA)
        case .b, .c:
            return .localized(.defaultBrowserPromptExperimentTitleVarBC)
        }
    }

    public static var image: UIImage? {
        switch variant {
        case .control:
            return .init(named: "defaultBrowser")
        case .a:
            return .init(named: "defaultBrowser") // TODO: Update image
        case .b, .c:
            return .init(named: "defaultBrowser") // TODO: Update image
        }
    }

    public static var buttonTitle: String {
        switch variant {
        case .control:
            return .localized(.defaultBrowserPromptExperimentButtonControl)
        case .a, .b, .c:
            return .localized(.defaultBrowserPromptExperimentButtonVarABC)
        }
    }

    // MARK: Content
    public enum ContentType: String {
        case checks
        case description
        case trivia
    }

    public static var contentType: ContentType {
        switch variant {
        case .control:
            return .checks
        case .a:
            return .description
        case .b, .c:
            return .trivia
        }
    }

    public static var checkItems: (String, String) {
        guard contentType == .checks else { return ("", "") }
        switch variant {
        case .control:
            return (.localized(.openAllLinksAutomatically), .localized(.beClimateActive))
        default:
            return ("", "")
        }
    }

    public static var description: String {
        guard contentType == .description else { return "" }
        switch variant {
        case .a:
            return .localized(.defaultBrowserPromptExperimentDescriptionVarA)
        default:
            return ""
        }
    }

    public static var trivia: NSMutableAttributedString {
        guard contentType == .trivia else { return .init() }
        var text = ""
        var highlight = ""
        switch variant {
        case .b:
            text = .localized(.defaultBrowserPromptExperimentDescriptionVarB)
            highlight = .localized(.defaultBrowserPromptExperimentDescriptionHighlightVarB)
        case .c:
            text = .localized(.defaultBrowserPromptExperimentDescriptionVarC)
            highlight = .localized(.defaultBrowserPromptExperimentDescriptionHighlightVarC)
        default:
            break
        }
        let fullText = String(format: text, highlight)
        let attributed = NSMutableAttributedString(string: fullText, attributes: [
            .font: UIFont.systemFont(ofSize: 16)
        ])
        if let range = fullText.range(of: highlight) {
            let nsRange = NSRange(range, in: fullText)
            attributed.addAttributes([
                .font: UIFont.boldSystemFont(ofSize: 16)
            ], range: nsRange)
        }
        return attributed
    }
}
