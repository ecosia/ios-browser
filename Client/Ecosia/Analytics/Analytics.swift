import Foundation
import SnowplowTracker
import Core

final class Analytics {
    static let shared = Analytics()
    private let tracker: SPTracker

    private init() {
        tracker = .build {
            $0?.setAppId(Bundle.version)
            $0?.setTrackerNamespace("ios_sp")
            
            $0?.setEmitter(.build {
                $0?.setUrlEndpoint(Environment.current.snowplow)
            })
            
            let subject = SPSubject(platformContext: true, andGeoContext: true)
            subject?.setUserId(User.shared.analyticsId.uuidString)
            $0?.setSubject(subject)
        }
    }
    
    func install() {
        SPSelfDescribingJson(schema: "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0", andData: ["app_v": Bundle.version] as NSObject).map { data in
            tracker.track(SPUnstructured.build {
                $0.setEventData(data)
            })
        }
    }
    
    func activity(_ action: Action.Activity) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.activity.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("inapp")
        })
    }

    func browser(_ action: Action.Browser, label: Label.Browser, property: Property? = nil) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel(label.rawValue)
            $0.setProperty(property?.rawValue)
        })
    }

    func navigation(_ action: Action, label: Label.Navigation) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel(label.rawValue)
        })
    }

    func navigationOpenNews(_ id: String) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel(Label.Navigation.news.rawValue)
            $0.setProperty(id)
        })
    }
    
    func navigationChangeMarket(_ new: String) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction("change")
            $0.setLabel("market")
            $0.setProperty(new)
        })
    }

    func migrationError(in migration: Migration, message: String) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.error.rawValue)
            $0.setLabel(migration.rawValue)
            $0.setProperty(message)
        })
    }
    
    func deeplink() {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("deeplink")
        })
    }
    
    func defaultBrowser() {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("default_browser_deeplink")
        })
    }
    
    func reset() {
        User.shared.analyticsId = .init()
        
        guard let subject = SPSubject(platformContext: true, andGeoContext: true) else { return }
        subject.setUserId(User.shared.analyticsId.uuidString)
        tracker.setSubject(subject)
    }
    
    func defaultBrowser(_ action: Action.Promo) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("default_browser_promo")
            $0.setProperty("home")
        })
    }

    func defaultBrowserSettings() {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("default_browser_settings")
        })
    }

    func migration(_ success: Bool) {
        tracker.track(SPStructured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(success ? Action.success.rawValue : Action.error.rawValue)
        }))
    }
    
    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        tracker.track(SPStructured.build({
            $0.setCategory(Category.migration.rawValue)
            $0.setAction(Action.completed.rawValue)
            $0.setLabel(migration.rawValue)
            $0.setValue(seconds * 1000)
        }))
    }
}
