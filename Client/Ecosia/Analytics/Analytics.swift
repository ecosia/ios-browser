import Foundation
import SnowplowTracker
import Core

final class Analytics {
    private static var tracker: TrackerController {
        Snowplow
            .createTracker(namespace: "ios_sp",
                           network: .init(endpoint: Environment.current.snowplow),
                           configurations: [TrackerConfiguration()
                                                .appId(Bundle.version)
                                                .platformContext(true)
                                                .geoLocationContext(true),
                                            SubjectConfiguration()
                                                .userId(User.shared.analyticsId.uuidString)])
    }
    
    static let shared = Analytics()
    private(set) var tracker: TrackerController

    private init() {
        tracker = Self.tracker
    }
    
    func install() {
        tracker
            .track(SelfDescribing(schema: "iglu:com.snowplowanalytics.snowplow/link_click/jsonschema/1-0-1",
                                  payload: ["app_v": Bundle.version as NSObject]))
    }
    
    func activity(_ action: Action.Activity) {
        tracker.track(Structured.build {
            $0.setCategory(Category.activity.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("inapp")
        })
    }

    func browser(_ action: Action.Browser, label: Label.Browser, property: Property? = nil) {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel(label.rawValue)
            $0.setProperty(property?.rawValue)
        })
    }

    func navigation(_ action: Action, label: Label.Navigation) {
        tracker.track(Structured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel(label.rawValue)
        })
    }

    func navigationOpenNews(_ id: String) {
        tracker.track(Structured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel(Label.Navigation.news.rawValue)
            $0.setProperty(id)
        })
    }
    
    func navigationChangeMarket(_ new: String) {
        tracker.track(Structured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction("change")
            $0.setLabel("market")
            $0.setProperty(new)
        })
    }

    func deeplink() {
        tracker.track(Structured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("deeplink")
        })
    }
    
    func defaultBrowser() {
        tracker.track(Structured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("default_browser_deeplink")
        })
    }
    
    func reset() {
        User.shared.analyticsId = .init()
        tracker = Self.tracker
    }
    
    func defaultBrowser(_ action: Action.Promo) {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("default_browser_promo")
            $0.setProperty("home")
        })
    }

    func defaultBrowserSettings() {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("default_browser_settings")
        })
    }

    func migration(_ success: Bool) {
        tracker.track(Structured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(success ? Action.success.rawValue : Action.error.rawValue)
        }))
    }

    func migrationError(in migration: Migration, message: String) {
        tracker.track(Structured.build {
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.error.rawValue)
            $0.setLabel(migration.rawValue)
            $0.setProperty(message)
        })
    }

    func migrationRetryHistory(_ success: Bool) {
        tracker.track(Structured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.retry.rawValue)
            $0.setLabel(Migration.history.rawValue)
            $0.setProperty(success ? Action.success.rawValue : Action.error.rawValue)
        }))
    }
    
    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        tracker
            .track(Structured(category: Category.migration.rawValue,
                              action: Action.completed.rawValue)
                    .label(migration.rawValue)
                    .value(.init(value: seconds * 1000)))
    }
    
    func open(topSite: Property.TopSite) {
        tracker.track(Structured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("top_sites")
            $0.setProperty(topSite.rawValue)
        })
    }
}
