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
    
    func open(_ action: Action.Activity) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.activity.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("inapp")
        })
    }
    
    func screen(_ label: Label.Screen) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(Action.view.rawValue)
            $0.setLabel(label.rawValue)
        })
    }
    
    func newTab(_ origin: Property) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("new_tab")
            $0.setProperty(origin.rawValue)
        })
    }
    
    func features(_ label: Label.Features, origin: Property) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel(label.rawValue)
            $0.setProperty(origin.rawValue)
        })
    }
    
    func market(_ new: String) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction("change")
            $0.setLabel("market")
            $0.setProperty(new)
        })
    }
    
    func more(_ label: Label.More) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel(label.rawValue)
        })
    }
    
    func shareApp(_ action: Action.Share) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("share_app")
        })
    }
    
    func shareContent(_ action: Action.Share) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("share_content")
        })
    }

    func favourites(_ action: Action.Favourites) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("favourites")
        })
    }
    
    func history(_ action: Action.History) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("history")
        })
    }
    
    func tabs(_ action: Action.Tabs) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("tabs")
        })
    }
    
    func news(_ id: String) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.navigation.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("news")
            $0.setProperty(id)
        })
    }

    func urlError(_ urlError: Error) {
        if let urlError = urlError as? URLError {
            switch urlError.code {
            case .networkConnectionLost,
                 .notConnectedToInternet,
                 .dnsLookupFailed,
                 .resourceUnavailable,
                 .unsupportedURL,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .timedOut,
                 .secureConnectionFailed,
                 .serverCertificateUntrusted:
                error(.init(urlError.code.rawValue))
            default:
                break
            }
        } else if (urlError as NSError).code == 101 { //urlCantBeShown
            error(.init(101))
        }
    }
    
    func error(_ code: String) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.receive.rawValue)
            $0.setLabel("error")
            $0.setProperty(code)
        })
    }
    
    func openOrganiser(_ feature: Label.Features) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel(feature.rawValue)
            $0.setProperty(Property.menu.rawValue)
        })
    }
    
    func onboarding(view label: Label.Onboarding) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.onboarding.rawValue)
            $0.setAction(Action.Onboarding.view.rawValue)
            $0.setLabel(label.rawValue)
        })
    }
    
    func onboarding(close label: Label.Onboarding) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.onboarding.rawValue)
            $0.setAction(Action.Onboarding.close.rawValue)
            $0.setLabel(label.rawValue)
        })
    }
    
    func openInSafari() {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.browser.rawValue)
            $0.setAction(Action.open.rawValue)
            $0.setLabel("safari")
            $0.setProperty(Property.menu.rawValue)
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
    
    func onboardingFinish() {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.onboarding.rawValue)
            $0.setAction(Action.Onboarding.finish.rawValue)
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
    
    func betaPromo(_ action: Action.Promo) {
        tracker.track(SPStructured.build {
            $0.setCategory(Category.external.rawValue)
            $0.setAction(action.rawValue)
            $0.setLabel("research_promo")
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

    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        tracker.track(SPTiming.build({
            $0.setCategory("migration")
            $0.setVariable(migration.rawValue)
            $0.setTiming(Int(seconds * 1000))
        }))
    }
}

private extension Navigation {
    var property: String {
        switch self {
        case let .organiser(organiser):
            return organiser.rawValue
        case .tabAnimated:
            return "search"
        case .news:
            return "news"
        default:
            return "home"
        }
    }
}
