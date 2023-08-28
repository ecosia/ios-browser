// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import Shared

protocol NTPCustomizationSettingsDelegate: AnyObject {
    func willDismissNTPCustomizationSettings()
}

final class NTPCustomizationSettingsViewController: SettingsTableViewController {
    var delegate: NTPCustomizationSettingsDelegate?
    
    // TODO: Dinamically fetch from homepage sections
    enum CustomizableSections: CaseIterable {
        case topSites
        case climateImpact
        case ecosiaNews
        
        var localizedTitleKey: String.Key {
            switch self {
            case .topSites: return .topSites
            case .climateImpact: return .climateImpact
            case .ecosiaNews: return .ecosiaNews
            }
        }
    }
    
    // TODO: Is Profile actually needed?
    init(profile: Profile) {
        super.init(style: .plain)
        self.profile = profile
        
        
        title = .localized(.homepage)
        navigationItem.rightBarButtonItem = .init(title: .localized(.done),
                                                  style: .done) { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func generateSettings() -> [SettingSection] {
        [SettingSection(title: .init(string: .localized(.showOnHomepage)), children: CustomizableSections
            .allCases.map { NTPCustomizationSetting(prefs: profile.prefs, setting: $0) })]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        delegate?.willDismissNTPCustomizationSettings()
    }
}

final class NTPCustomizationSetting: BoolSetting {
    
    private var setting: NTPCustomizationSettingsViewController.CustomizableSections = .topSites
    
    convenience init(prefs: Prefs, setting: NTPCustomizationSettingsViewController.CustomizableSections) {
        self.init(prefs: prefs,
                  defaultValue: true,
                  titleText: .localized(setting.localizedTitleKey)) { value in
            switch setting {
            case .topSites: User.shared.showTopSites = value
            case .climateImpact: User.shared.showClimateImpact = value
            case .ecosiaNews: User.shared.showEcosiaNews = value
            }
        }
        self.setting = setting
    }

    override func displayBool(_ control: UISwitch) {
        switch setting {
        case .topSites: control.isOn = User.shared.showTopSites
        case .climateImpact: control.isOn = User.shared.showClimateImpact
        case .ecosiaNews: control.isOn = User.shared.showEcosiaNews
        }
    }

    override func writeBool(_ control: UISwitch) {
        switch setting {
        case .topSites: User.shared.showTopSites = control.isOn
        case .climateImpact: User.shared.showClimateImpact = control.isOn
        case .ecosiaNews: User.shared.showEcosiaNews = control.isOn
        }
    }
}
