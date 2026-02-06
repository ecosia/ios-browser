// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Accounts
import Common
import Shared

/// Ecosia: Custom search engine provider that ensures Ecosia is always the default search engine.
/// Wraps ASSearchEngineProvider to use Remote Settings while maintaining Ecosia as default.
final class EcosiaSearchEngineProvider: SearchEngineProvider, Sendable {
    private let asProvider: ASSearchEngineProvider
    private let logger: Logger
    
    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        self.asProvider = ASSearchEngineProvider(logger: logger)
    }
    
    // MARK: - SearchEngineProvider
    
    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v2
    
    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        // Delegate to AS provider
        asProvider.getOrderedEngines(customEngines: customEngines,
                                     engineOrderingPrefs: engineOrderingPrefs,
                                     prefsMigrator: prefsMigrator) { [weak self] prefs, engines in
            // Ecosia: Ensure Ecosia is always the default (position 0)
            let finalEngines = self?.ensureEcosiaIsDefault(engines) ?? engines
            completion(prefs, finalEngines)
        }
    }
    
    // MARK: - Private
    
    /// Ensures Ecosia is always at position 0 in the engines list.
    /// If Ecosia is not found, logs a warning but returns the original list.
    private func ensureEcosiaIsDefault(_ engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        // Find Ecosia engine
        guard let ecosiaIndex = engines.firstIndex(where: { engine in
            engine.shortName.lowercased().contains("ecosia") ||
            engine.engineID.lowercased().contains("ecosia") == true
        }) else {
            logger.log("[Ecosia] Ecosia search engine not found in engine list. Available engines: \(engines.map { $0.shortName })",
                      level: .warning,
                      category: .remoteSettings)
            return engines
        }
        
        // Already at position 0
        if ecosiaIndex == 0 {
            logger.log("[Ecosia] Ecosia is already the default search engine",
                      level: .info,
                      category: .remoteSettings)
            return engines
        }
        
        // Move Ecosia to position 0
        var reorderedEngines = engines
        let ecosiaEngine = reorderedEngines.remove(at: ecosiaIndex)
        reorderedEngines.insert(ecosiaEngine, at: 0)
        
        logger.log("[Ecosia] Moved Ecosia from position \(ecosiaIndex) to position 0 (default)",
                  level: .info,
                  category: .remoteSettings)
        
        return reorderedEngines
    }
}
