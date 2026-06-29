// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Accounts
import Common
import Shared
import UIKit

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
    /// If Ecosia is not found, injects a bundled fallback engine at position 0.
    private func ensureEcosiaIsDefault(_ engines: [OpenSearchEngine]) -> [OpenSearchEngine] {
        // Find Ecosia engine
        guard let ecosiaIndex = engines.firstIndex(where: { engine in
            engine.shortName.lowercased().contains("ecosia") ||
            engine.engineID.lowercased().contains("ecosia") == true
        }) else {
            // Mozilla's Remote Settings only includes Ecosia for the German language or a small
            // set of EU regions (MOB-4673). For every other locale/region the list comes back
            // without Ecosia and Mozilla's default (Google) would be shown. Inject a fallback
            // Ecosia engine at position 0 so Ecosia is the default regardless of locale/region,
            // restoring the guarantee previously provided by the bundled `ecosia.xml`.
            logger.log("[Ecosia] Ecosia search engine not found in engine list; injecting fallback. Available engines: \(engines.map { $0.shortName })",
                       level: .warning,
                       category: .remoteSettings)
            return [makeFallbackEcosiaEngine()] + engines
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

    // MARK: - Fallback engine

    /// Builds an Ecosia `OpenSearchEngine` used when Remote Settings does not return one.
    /// Mirrors the engine the bundled `ecosia.xml` used to provide. Note that `OpenSearchEngine`
    /// already routes searches through `URL.ecosiaSearchWithQuery(_:)`, so the search template is
    /// only used for recognising Ecosia result URLs; the suggest template drives autocomplete.
    private func makeFallbackEcosiaEngine() -> OpenSearchEngine {
        return OpenSearchEngine(
            engineID: FallbackEngine.engineID,
            shortName: FallbackEngine.shortName,
            telemetrySuffix: nil,
            image: fallbackEcosiaImage(),
            searchTemplate: FallbackEngine.searchTemplate,
            suggestTemplate: FallbackEngine.suggestTemplate,
            trendingTemplate: nil,
            isCustomEngine: false
        )
    }

    private func fallbackEcosiaImage() -> UIImage {
        if let data = Data(base64Encoded: FallbackEngine.iconBase64),
           let image = UIImage(data: data) {
            return image
        }
        // The icon is a compile-time constant so this should never be reached; fall back to a
        // bundled Ecosia asset to keep a non-empty image (OpenSearchEngine asserts on empty images).
        return UIImage(named: "ecosiaHomeHeaderLogoBall") ?? UIImage()
    }

    private enum FallbackEngine {
        static let engineID = "ecosia"
        static let shortName = "Ecosia"
        static let searchTemplate = "https://www.ecosia.org/search?q={searchTerms}"
        static let suggestTemplate = "https://ac.ecosia.org/autocomplete?q={searchTerms}&type=list"
        // 16x16 Ecosia favicon, identical to the one in the legacy bundled `ecosia.xml`.
        static let iconBase64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAIKADAAQAAAABAAAAIAAAAACshmLzAAADJUlEQVRYCb1XQWgTQRT9s0lRsy1pbVMKxkvQeqo9RqkgShAkBrVVMB560mMvgr0XPVkhB/GkJw8NeBCLiKBSRBTJUXuVIhJEbLUN7VYlS8b/NzPbzc5md9OYLCwz8+f9//7O7P/zh3HONQjxbG2txWo1yHHOTgPwMVRJ4dsvVDewXQFgy4zxJU2DZ729Q9tizrdhQQ5sbq4dqtXYTSS9ipZivtZ2JpGcLWgan+/rG/q8I1Z7TR0QXzzHOcygWo+qGkpSRVQhEoFbzVbE04H6V8NjVB4PRRMMKkWjbFLXB7+7oYoDlcrqUVy+lwhMuMFtjsu4jbl4PPHJaafBAfHl79zk117MwNLXt069wP7UaA7mT91248q4EmnnSkQlQuw5Lbvy5ZW/Ffj1e11CQ7XrfypeuKRp8ifIlZH/hB2CGGJzqPG/9tyLXMrSpgmzcmA5QEsv/nYp72jLGNwwjJ8jRGI5UI/zXYfabpzVcRVoxUGjvRdJZjeG2tDheeLWKL2ilbAZrg1CRVVH7mxU5HZlNkhw/8xduDh6LgjmO4/cGQxD62DxBXpN6j06xKLtLhwfozyQ8iIIkr0vf1AgidggTBw4psh9BClyQB6pPjh16sHHR0Cv8zl58AQsTrXkQL8Vhk4j3e7TClAxoaTfIEeuj0/DRPJ4A2xEH24YhxhskANYybTuAJFfOJwNweELWUEH2DJGQtoX5jFpVA3YNv2rruAowRIOz/88ngMLHhy26PLTaXj15Y09DtO5dOQ8PDx7zxeKZ8IVjQpIRBm+yM5MGsj9XKufy6zYGQ4/q6xI3FYYUvWKUCogu/VUBWf9OBalc6Fb7MhTkOW6nYiodMaJUhecKAkui4rygPXQfmCVMok1GzmRFGKrie+Jw/59A05RYH9gb1zB4F//LRKxynM7fhuqYtIQZTlFRoMTirXWBeXAslzaNIwfCdPUFnHccoKSNlxt04uJ/Q84FXR9eBX3KYMJiv6LdnIERdYdsuW8Czi5lC1wTlKfqtd6AcnzONTd803G6DQrtnU5dRsWF5cslVGiikohRtYSzuv5a8pw8uLhtuMe/wPt6BOLAKidswAAAABJRU5ErkJggg=="
    }
}
