import Foundation
import SnowplowTracker
import Core


final class Analytics {
    private static let installSchema = "iglu:org.ecosia/ios_install_event/jsonschema/1-0-0"
    private static let abTestSchema = "iglu:org.ecosia/abtest_context/jsonschema/1-0-1"
    private static let abTestRoot = "ab_tests"
    private static let namespace = "ios_sp"

    private static var tracker: TrackerController {
        
        let trackerConfiguration = TrackerConfiguration()
            .appId(Bundle.version)
            .sessionContext(true)
            .applicationContext(true)
            .platformContext(true)
            .platformContextProperties([]) // track minimal device properties
            .geoLocationContext(true)
            .deepLinkContext(false)
            .screenContext(false)
        
        let subjectConfiguration = SubjectConfiguration()
            .userId(User.shared.analyticsId.uuidString)
        
        return Snowplow.createTracker(namespace: namespace,
                                      network: .init(endpoint: Environment.current.urlProvider.snowplow),
                                      configurations: [trackerConfiguration, subjectConfiguration])!
    }
    
    static let shared = Analytics()
    private var tracker: TrackerController
    
    private init() {
        tracker = Self.tracker
        tracker.installAutotracking = true
        tracker.screenViewAutotracking = false
        tracker.lifecycleAutotracking = false
        tracker.exceptionAutotracking = false
        tracker.diagnosticAutotracking = false
    }
    
    private func track(_ event: Event) {
        guard User.shared.sendAnonymousUsageData else { return }
        tracker.track(event)
    }
    
    private static func getTestContext(from toggle: Unleash.Toggle.Name) -> SelfDescribingJson? {
        let variant = Unleash.getVariant(toggle).name
        guard variant != "disabled" else { return nil }

        let variantContext: [String: String] = [toggle.rawValue: variant]
        let abTestContext: [String: AnyHashable] = [abTestRoot: variantContext]
        return SelfDescribingJson(schema: abTestSchema, andDictionary: abTestContext)
    }
    
    func install() {
        track(SelfDescribing(schema: Self.installSchema,
                             payload: ["app_v": Bundle.version as NSObject]))
    }
    
    func reset() {
        User.shared.analyticsId = .init()
        tracker = Self.tracker
    }
    
    func activity(_ action: Action.Activity) {
        let event = Structured(category: Category.activity.rawValue,
                               action: action.rawValue)
            .label("inapp")
        
        switch action {
        case .resume, .launch:
            // add A/B Test context
            if let context = Self.getTestContext(from: .bingSearch) {
                event.contexts.append(context)
            }
        }
        
        track(event)
    }
    
    func browser(_ action: Action.Browser, label: Label.Browser, property: Property? = nil) {
        track(Structured(category: Category.browser.rawValue,
                         action: action.rawValue)
            .label(label.rawValue)
            .property(property?.rawValue))
    }
    
    func navigation(_ action: Action, label: Label.Navigation) {
        track(Structured(category: Category.navigation.rawValue,
                         action: action.rawValue)
            .label(label.rawValue))
    }
    
    func navigationOpenNews(_ id: String) {
        track(Structured(category: Category.navigation.rawValue,
                         action: Action.open.rawValue)
            .label(Label.Navigation.news.rawValue)
            .property(id))
    }
    
    func navigationChangeMarket(_ new: String) {
        track(Structured(category: Category.navigation.rawValue,
                         action: "change")
            .label("market")
            .property(new))
    }
    
    func deeplink() {
        track(Structured(category: Category.external.rawValue,
                         action: Action.receive.rawValue)
            .label("deeplink"))
    }
    
    func appOpenAsDefaultBrowser() {
        track(Structured(category: Category.external.rawValue,
                         action: Action.receive.rawValue)
            .label("default_browser_deeplink"))
    }
    
    func defaultBrowser(_ action: Action.Promo) {
        let event = Structured(category: Category.browser.rawValue,
                               action: action.rawValue)
            .label("default_browser_promo")
            .property("home")
        
        // add A/B Test context
        if let context = Self.getTestContext(from: .defaultBrowser) {
            event.contexts.append(context)
        }
        
        track(event)
    }
    
    func userSearchViaBingABTest() {
        let event = Structured(category: Category.abTest.rawValue,
                               action: "user_search")
            .label("search_key")
        
        track(event)
    }
    
    func defaultBrowserSettings() {
        track(Structured(category: Category.browser.rawValue,
                         action: Action.open.rawValue)
            .label("default_browser_settings"))
    }
    
    func migration(_ success: Bool) {
        track(Structured(category: Category.migration.rawValue,
                         action: success ? Action.success.rawValue : Action.error.rawValue))
    }
    
    func migrationError(in migration: Migration, message: String) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.error.rawValue)
            .label(migration.rawValue)
            .property(message))
    }
    
    func migrationRetryHistory(_ success: Bool) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.retry.rawValue)
            .label(Migration.history.rawValue)
            .property(success ? Action.success.rawValue : Action.error.rawValue))
    }
    
    func migrated(_ migration: Migration, in seconds: TimeInterval) {
        track(Structured(category: Category.migration.rawValue,
                         action: Action.completed.rawValue)
            .label(migration.rawValue)
            .value(.init(value: seconds * 1000)))
    }
    
    func openInvitations() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.view.rawValue)
            .label("invite_screen"))
    }
    
    func startInvite() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.click.rawValue)
            .label("invite"))
    }
    
    func sendInvite() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.send.rawValue)
            .label("invite"))
    }
    
    func showInvitePromo() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.view.rawValue)
            .label("promo"))
    }
    
    func openInvitePromo() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.open.rawValue)
            .label("promo"))
    }
    
    func inviteClaimSuccess() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.claim.rawValue))
    }
    
    func inviteCopy() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.click.rawValue)
            .label("link_copying"))
    }
    
    func inviteLearnMore() {
        track(Structured(category: Category.invitations.rawValue,
                         action: Action.click.rawValue)
            .label("learn_more"))
    }
    
    func clickYourImpact(on category: Category) {
        track(Structured(category: category.rawValue,
                         action: Action.click.rawValue)
            .label("your_impact"))
    }
    
    func searchbarChanged(to position: String) {
        track(Structured(category: Category.settings.rawValue,
                         action: Action.change.rawValue)
            .label("toolbar")
            .property(position))
    }
    
    func menuClick(_ item: String) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label(item)
        track(event)
    }
    
    func menuStatus(changed item: String, to: Bool) {
        let event = Structured(category: Category.menuStatus.rawValue,
                               action: Action.click.rawValue)
            .label(item)
            .value(.init(value: to))
        track(event)
    }
    
    func menuShare(_ content: ShareContent) {
        let event = Structured(category: Category.menu.rawValue,
                               action: Action.click.rawValue)
            .label("share")
            .property(content.rawValue)
        track(event)
    }
    
}
