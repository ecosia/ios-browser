import Foundation

struct AppUpdateRule: RefreshingRule {

    private var currentAppVersion: String?

    init(appVersion: String) {
        self.currentAppVersion = appVersion
    }

    var shouldRefresh: Bool {
        currentAppVersion != Unleash.model.appVersion
    }
}
