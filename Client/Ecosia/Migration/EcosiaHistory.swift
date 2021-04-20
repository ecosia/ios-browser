/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import Storage
import Shared

final class EcosiaHistory {

    struct Data {
        let domains: [String: Int]
        let sites: [Site: Int]
        let visits: [(SiteVisit, Int)]
    }

    struct Item {
        let index: Int
        let page: Core.Page
        let date: Date
        let site: Site
    }

    static var start: Date?
    static func migrate(_ historyItems: [(Date, Core.Page)], to profile: Profile, progress: ((Double) -> ())? = nil, finished: @escaping (Result<Void, EcosiaImport.Failure>) -> ()){

        guard !historyItems.isEmpty else {
            finished(.success(()))
            return
        }

        start = Date()
        DispatchQueue.global(qos: .userInitiated).async {
            let data = prepare(history: historyItems, progress: progress)
            guard !profile.isShutdown else {
                finished(.failure(.init(reasons: [NSError(domain: "Database is shutdown", code: EcosiaImport.Failure.Code.history.rawValue)])))
                return
            }

            DispatchQueue.main.async {
                insertData(data, to: profile, finished: finished)
            }
        }
    }

    static func insertData(_ data: EcosiaHistory.Data, to profile: Profile, finished: @escaping (Result<Void, EcosiaImport.Failure>) -> ()){

        guard let history = profile.history as? SQLiteHistory else { return }

        let success = history.clearHistory()
            >>> { history.storeDomains(data.domains) }
            >>> { history.storeSites(data.sites) }
            >>> { history.storeVisits(data.visits) }

        success.uponQueue(.main) { (result) in
            let duration = Date().timeIntervalSince(start ?? Date())
            Analytics.shared.migrated(.history, in: duration)

            // make UI update
            history.setTopSitesNeedsInvalidation()
            profile.panelDataObservers.activityStream.refreshIfNeeded(forceTopSites: true)

            switch result {
            case .success:
                finished(.success(()))
            case .failure(let error):
                finished(.failure(.init(reasons: [error])))
            }
        }

    }

    static func prepare(history: [(Date, Core.Page)], progress: ((Double) -> ())? = nil) -> EcosiaHistory.Data {
        // extract distinct domains
        var domains = [String: Int]() //unique per domain e.g. ecosia.org + domain_id
        var sites = [Site: Int]() // unique per url e.g. ecosia.org/search?q=foo + domain_id
        var visits = [(SiteVisit, Int)]() // all visitis + site_id

        for (i, item) in history.enumerated() {
            guard let domain = item.1.url.normalizedHost, !isIgnoredURL(domain) else { continue }
            var domainIndex: Int
            if let index = domains[domain] {
                domainIndex = index
            } else {
                domainIndex = domains.count + 1
                domains[domain] = domainIndex
            }

            var site: Site
            if let match = sites.first(where: { $0.key.url == item.1.url.absoluteString }) {
                site = match.key
            } else {
                site = Site(url: item.1.url.absoluteString, title: item.1.title)
                site.id = sites.count + 1
                sites[site] = domainIndex
            }

            // add all visits
            let visit = SiteVisit(site: site, date: item.0.toMicrosecondTimestamp())
            visits.append((visit, site.id!))

            // only report every 50th entry to not over-report
            if i % 50 == 0 {
                DispatchQueue.main.async {
                    progress?(Double(i)/Double(history.count))
                }
            }

        }
        return .init(domains: domains, sites: sites, visits: visits)
    }
}
