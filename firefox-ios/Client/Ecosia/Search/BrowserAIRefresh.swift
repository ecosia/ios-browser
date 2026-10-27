// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import Shared

/// Page summaries and translations follow `AIFreeSearchingSelection.blocksBrowserAI`, which
/// depends on the AI-free searching toggle and on the search provider. When either changes,
/// this tells the window, as Firefox's own settings screens do, so its toolbar buttons
/// update without waiting for the next page load. Menus are rebuilt each time they open and
/// need no refresh.
enum BrowserAIRefresh {
    @MainActor
    static func dispatch(prefs: Prefs, windowUUID: WindowUUID) {
        store.dispatch(ToolbarAction(
            canSummarize: DefaultSummarizerNimbusUtils().isSummarizeFeatureToggledOn,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didSummarizeSettingsChange
        ))
        let isTranslationsEnabled = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        store.dispatch(TranslationsAction(
            isTranslationsEnabled: isTranslationsEnabled,
            translationConfiguration: TranslationConfiguration(prefs: prefs, isUserSettingEnabled: isTranslationsEnabled),
            windowUUID: windowUUID,
            actionType: TranslationsActionType.didTranslationSettingsChange
        ))
    }

    /// Runs `change` and tells the window only if it changed whether AI-free searching blocks
    /// page summaries and translations. The refresh also resets the window's translation
    /// target language, so it is not sent for changes that leave the result as it was.
    @MainActor
    static func dispatchIfChanged(prefs: Prefs, windowUUID: WindowUUID, by change: () -> Void) {
        let blockedBefore = AIFreeSearchingSelection.blocksBrowserAI
        change()
        guard AIFreeSearchingSelection.blocksBrowserAI != blockedBefore else { return }
        dispatch(prefs: prefs, windowUUID: windowUUID)
    }
}
