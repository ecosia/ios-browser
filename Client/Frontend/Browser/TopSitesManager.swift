/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import Storage
import SyncTelemetry
import WidgetKit

struct TopSitesHandler {
    static func getTopSites(profile: Profile) -> Deferred<[Site]> {      
        let maxItems = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        return profile.history.getTopSitesWithLimit(maxItems).both(profile.history.getPinnedTopSites()).bindQueue(.main) { (topsites, pinnedSites) in
            
            let deferred = Deferred<[Site]>()
                        
            guard let mySites = topsites.successValue?.asArray(), let pinned = pinnedSites.successValue?.asArray() else {
                return deferred
            }
            
            // How sites are merged together. We compare against the url's base domain. example m.youtube.com is compared against `youtube.com`
            let unionOnURL = { (site: Site) -> String in
                return URL(string: site.url)?.normalizedHost ?? ""
            }

            /* Ecosia: Merge default sites including path to keep blog.ecosia.org + blog.ecosia.org/financial-results */
            let unionOnURLAndPath = { (site: Site) -> String in
                return URL(string: site.url)?.normalizedHostAndPath ?? ""
            }

            // Fetch the default sites
            let defaultSites = defaultTopSites(profile)
            // create PinnedSite objects. used by the view layer to tell topsites apart
            let pinnedSites: [Site] = pinned.map({ PinnedSite(site: $0) })

            // Merge pinned sites with a user's topsites.
            let mergedSites = pinnedSites.union(mySites, f: unionOnURL)
            // Merge default sites into mergedSites
            let allSites = mergedSites.union(defaultSites, f: unionOnURLAndPath)

            /* Ecosia: Favour default sites over top sites as they have better icons and texts. But keep PinnedSites */
            let newSites = allSites.map { site -> Site in
                if let _ = site as? PinnedSite {
                    return site
                }
                return defaultSites.first(where: { $0.url.asURL?.normalizedHostAndPath == site.url.asURL?.normalizedHostAndPath }) ?? site
            }
            
            deferred.fill(newSites)
            
            return deferred
        }
    }
    
    @available(iOS 14.0, *)
    static func writeWidgetKitTopSites(profile: Profile) {
        TopSitesHandler.getTopSites(profile: profile).uponQueue(.main) { result in
            var widgetkitTopSites = [WidgetKitTopSiteModel]()
            result.forEach { site in
                // Favicon icon url
                let iconUrl = site.icon?.url ?? ""
                let imageKey = site.tileURL.baseDomain ?? ""
                if let webUrl = URL(string: site.url) {
                    widgetkitTopSites.append(WidgetKitTopSiteModel(title: site.title, faviconUrl: iconUrl, url: webUrl, imageKey: imageKey))
                    // fetch favicons and cache them on disk
                    FaviconFetcher.downloadFaviconAndCache(imageURL: !iconUrl.isEmpty ? URL(string: iconUrl) : nil, imageKey: imageKey )
                }
            }
            // save top sites for widgetkit use
            WidgetKitTopSiteModel.save(widgetKitTopSites: widgetkitTopSites)
            // Update widget timeline
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static func defaultTopSites(_ profile: Profile) -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.firstIndex(of: $0.url) == .none})
    }
    
    static let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"
}

open class PinnedSite: Site {
    let isPinnedSite = true

    init(site: Site) {
        super.init(url: site.url, title: site.title, bookmarked: site.bookmarked)
        self.icon = site.icon
        self.metadata = site.metadata
    }
}