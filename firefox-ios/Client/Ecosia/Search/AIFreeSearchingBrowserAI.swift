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
    /// tells the window, so its toolbar buttons update straight away. Each browser window runs it
    /// when AI-free searching turns on or off, in Settings or on the web (`aiFreeSearchingChanged`).
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

    /// Keeps one browser window's page summaries and translations in line with AI-free searching,
    /// whether it changed in Settings or on the web (the `ECNOAI` cookie). Each window holds one.
    final class WindowObserver: NSObject {
        private let prefs: Prefs
        private let windowUUID: WindowUUID

        init(prefs: Prefs, windowUUID: WindowUUID, notificationCenter: NotificationCenter = .default) {
            self.prefs = prefs
            self.windowUUID = windowUUID
            super.init()
            notificationCenter.addObserver(self,
                                           selector: #selector(aiFreeSearchingChanged),
                                           name: .aiFreeSearchingChanged,
                                           object: nil)
        }

        @objc
        nonisolated private func aiFreeSearchingChanged() {
            ensureMainThread { [prefs, windowUUID] in
                AIFreeSearchingBrowserAI.apply(aiFreeSearching: User.shared.aiFreeSearching == true,
                                               prefs: prefs,
                                               windowUUID: windowUUID)
            }
        }
    }

    /// Users who turned AI-free searching on before page summaries and translations arrived
    /// start with both off, as if they had just turned it on. Settings the user has already
    /// chosen are left alone. Runs at launch, once the cached Unleash flags are loaded.
    ///
    /// Only while Settings offers AI-free searching: when the flag is off or a custom search
    /// provider is in use, the toggle is hidden and both rows are in General, where switching
    /// them off would have no visible reason. The check runs again at every launch, so it
    /// applies once AI-free searching is offered again.
    static func switchOffForExistingAIFreeUsers(prefs: Prefs) {
        guard AIFreeSearchingSelection.isAvailable, User.shared.aiFreeSearching == true else { return }
        for key in [PrefsKeys.Summarizer.summarizeContentFeature, PrefsKeys.Settings.translationsFeature]
        where prefs.boolForKey(key) == nil {
            prefs.setBool(false, forKey: key)
        }
    }
}
