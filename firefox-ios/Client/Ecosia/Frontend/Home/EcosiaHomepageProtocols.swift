// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Ecosia: Local definitions for Ecosia NTP/homepage view models.
// Firefox removed HomepageViewModelProtocol, HomepageDataModelDelegate, and LabelButtonHeaderViewModel
// in the rebuild; Ecosia keeps these types so NTP sections (e.g. NTPConfigurableNudgeCardCellViewModel)
// and data reload (e.g. NTPNewsCellViewModel) continue to work without touching Firefox code.

import Common
import UIKit

// MARK: - HomepageDataModelDelegate

/// Delegate used by Ecosia section view models to request a full view reload (e.g. after news data loads).
protocol HomepageDataModelDelegate: AnyObject {
    func reloadView()
}

// MARK: - LabelButtonHeaderViewModel

/// View model for section headers with optional title and button (e.g. "News" + "See all").
struct LabelButtonHeaderViewModel {
    let title: String?
    let titleA11yIdentifier: String?
    let isButtonHidden: Bool
    let buttonTitle: String?
    let buttonAction: ((UILabel) -> Void)?
    let buttonA11yIdentifier: String?

    nonisolated(unsafe) static let emptyHeader = LabelButtonHeaderViewModel(
        title: nil,
        titleA11yIdentifier: nil,
        isButtonHidden: true,
        buttonTitle: nil,
        buttonAction: nil,
        buttonA11yIdentifier: nil
    )

    init(title: String?,
         titleA11yIdentifier: String?,
         isButtonHidden: Bool,
         buttonTitle: String?,
         buttonAction: ((UILabel) -> Void)?,
         buttonA11yIdentifier: String?) {
        self.title = title
        self.titleA11yIdentifier = titleA11yIdentifier
        self.isButtonHidden = isButtonHidden
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.buttonA11yIdentifier = buttonA11yIdentifier
    }
}

// MARK: - HomepageViewModelProtocol

/// Protocol for Ecosia homepage/NTP section view models (header, layout, theme, visibility).
@MainActor
protocol HomepageViewModelProtocol: AnyObject {
    var sectionType: HomepageSectionType { get }
    var headerViewModel: LabelButtonHeaderViewModel { get }
    var isEnabled: Bool { get }

    func setTheme(theme: Theme)
    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection
    func numberOfItemsInSection() -> Int
    func screenWasShown()
}
