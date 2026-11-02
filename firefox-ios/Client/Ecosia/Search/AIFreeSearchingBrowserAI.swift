// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared

/// AI-free searching takes the place of Firefox's AI controls hub. Turning it on switches page
/// summaries and translations off, as the hub's "Block AI enhancements" switch does, and turning
/// it off switches them back on. Both keep Firefox's own settings, so while AI-free searching is
/// on the user can turn either back on from the rows Settings lists under its toggle.
enum AIFreeSearchingBrowserAI {
    /// Writes Firefox's page summaries and translations settings for the new AI-free value and
    /// tells the open window, so its toolbar buttons update straight away.
    @MainActor
    static func apply(aiFreeSearching isOn: Bool, prefs: Prefs, windowUUID: WindowUUID) {
        let isEnabled = !isOn
        prefs.setBool(isEnabled, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        store.dispatch(ToolbarAction(
            canSummarize: DefaultSummarizerNimbusUtils().isSummarizeFeatureToggledOn,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didSummarizeSettingsChange
        ))
        // Firefox's translation settings write the setting, update the toolbar and, when
        // switching off, delete the downloaded models, as they do for the AI controls hub.
        store.dispatch(TranslationSettingsViewAction(
            newSettingValue: isEnabled,
            toggledViaAIControls: true,
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        ))
    }

    /// Users who turned AI-free searching on before page summaries and translations arrived
    /// start with both off, as if they had just turned it on. Settings the user has already
    /// chosen are left alone. Runs at launch.
    static func switchOffForExistingAIFreeUsers(prefs: Prefs) {
        guard User.shared.aiFreeSearching == true else { return }
        for key in [PrefsKeys.Summarizer.summarizeContentFeature, PrefsKeys.Settings.translationsFeature]
        where prefs.boolForKey(key) == nil {
            prefs.setBool(false, forKey: key)
        }
    }
}
