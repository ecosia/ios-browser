// This file was autogenerated by the `nimbus-fml` crate.
// Trust me, you don't want to mess with it!
#if canImport(Foundation)
    import Foundation
#endif
#if canImport(MozillaAppServices)
    import MozillaAppServices
#endif
#if canImport(UIKit)
    import UIKit
#endif

///
/// An object for safely accessing feature configuration from Nimbus.
///
/// This is generated.
public class FxNimbusMessaging : FeatureManifestInterface {
    public typealias Features = FxNimbusMessagingFeatures

    ///
    /// This should be populated at app launch; this method of initializing features
    /// will be removed in favor of the `initialize` function.
    ///
    public var api: FeaturesInterface?

    ///
    /// This method should be called as early in the startup sequence of the app as possible.
    /// This is to connect the Nimbus SDK (and thus server) with the `FxNimbusMessaging`
    /// class.
    ///
    /// The lambda MUST be threadsafe in its own right.
    public func initialize(with getSdk: @escaping () -> FeaturesInterface?) {
        self.getSdk = getSdk
        self.features.messaging.with(sdk: getSdk)
        self.reinitialize()
    }

    fileprivate lazy var getSdk: GetSdk = { [self] in self.api }

    ///
    /// Represents all the features supported by Nimbus
    ///
    public let features = Features()

    public func getCoenrollingFeatureIds() -> [String] {
        ["messaging"]
    }

    /// Introspection utility method.
    public func getFeature(featureId: String) -> FeatureHolderAny? {
        switch featureId {
            case "messaging": return FeatureHolderAny(wrapping: features.messaging)
            default: return nil
        }
    }

    ///
    /// All generated initialization code. Clients shouldn't need to override or call
    /// this.
    /// We put it in a separate method because we have to be quite careful about what order
    /// the initialization happens in— e.g. when importing other FML files.
    ///
    private func reinitialize() {
        // Nothing left to do.
    }

    ///
    /// Refresh the cache of configuration objects.
    ///
    /// For performance reasons, the feature configurations are constructed once then cached.
    /// This method is to clear that cache for all features configured with Nimbus.
    ///
    /// It must be called whenever the Nimbus SDK finishes the `applyPendingExperiments()` method.
    ///
    public func invalidateCachedValues() {
        features.messaging.with(cachedValue: nil)
    }

    ///
    /// A singleton instance of FxNimbusMessaging
    ///
    public static let shared = FxNimbusMessaging()
}

public class FxNimbusMessagingFeatures {
    /// The in-app messaging system
         /// 
    public lazy var messaging: FeatureHolder<Messaging> = {
        FeatureHolder(FxNimbusMessaging.shared.getSdk, featureId: "messaging") { variables, prefs in
            Messaging(variables, prefs)
        }
    }()
}

// Public interface members begin here.

/// The in-app messaging system
 /// 
public class Messaging: FMLObjectInterface {
    private let _variables: Variables
    private let _defaults: Defaults
    private let _prefs: UserDefaults?

    private init(variables: Variables = NilVariables.instance, prefs: UserDefaults? = nil, defaults: Defaults) {
        self._variables = variables
        self._defaults = defaults
        self._prefs = prefs
    }
    
    struct Defaults {
        let actions: [String: String]
        let messageUnderExperiment: String?
        let messages: [String: MessageData]
        let onControl: ControlMessageBehavior
        let styles: [String: StyleData]
        let triggers: [String: String]
        let experiment: String
    }

    public convenience init(
        _ _variables: Variables = NilVariables.instance,
        _ _prefs: UserDefaults? = nil,
        actions: [String: String] = [:],
        messageUnderExperiment: String? = nil,
        messages: [String: MessageData] = [:],
        onControl: ControlMessageBehavior = .showNextMessage,
        styles: [String: StyleData] = [:],
        triggers: [String: String] = ["ALWAYS": "true", "NEVER": "false"],
        experiment: String = "{experiment}"
    ) {
        self.init(variables: _variables, prefs: _prefs, defaults: Defaults(
            actions: actions,
            messageUnderExperiment: messageUnderExperiment,
            messages: messages,
            onControl: onControl,
            styles: styles,
            triggers: triggers,
            experiment: experiment))
    }

    enum CodingKeys: String, CodingKey {
        case actions = "actions"
        case messageUnderExperiment = "message-under-experiment"
        case messages = "messages"
        case onControl = "on-control"
        case styles = "styles"
        case triggers = "triggers"
        case experiment = "~~experiment"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(actions, forKey: .actions)
        try container.encode(messageUnderExperiment, forKey: .messageUnderExperiment)
        try container.encode(messages, forKey: .messages)
        try container.encode(onControl.rawValue, forKey: .onControl)
        try container.encode(styles, forKey: .styles)
        try container.encode(triggers, forKey: .triggers)
        try container.encode(experiment, forKey: .experiment)
    }

    /// A growable map of action URLs.
    public lazy var actions: [String: String] = {
        self._variables.getStringMap("actions")?.mergeWith(_defaults.actions) ?? _defaults.actions
    }()
    
    /// Deprecated. Please use "experiment": "{experiment}" instead.
    public lazy var messageUnderExperiment: String? = {
        self._variables.getString("message-under-experiment") ?? _defaults.messageUnderExperiment
    }()
    
    /// A growable collection of messages, where the Key is the message identifier
     /// and the value is its associated MessageData.
     /// 
    public lazy var messages: [String: MessageData] = {
        self._variables.getVariablesMap("messages")?.mapValuesNotNull(MessageData.create).mergeWith(_defaults.messages, MessageData.mergeWith) ?? _defaults.messages
    }()
    
    /// What should be displayed when a control message is selected.
    public lazy var onControl: ControlMessageBehavior = {
        self._variables.getString("on-control")?.map(ControlMessageBehavior.enumValue) ?? _defaults.onControl
    }()
    
    /// A map of styles to configure message appearance.
     /// 
    public lazy var styles: [String: StyleData] = {
        self._variables.getVariablesMap("styles")?.mapValuesNotNull(StyleData.create).mergeWith(_defaults.styles, StyleData.mergeWith) ?? _defaults.styles
    }()
    
    /// A collection of out the box trigger expressions. Each entry maps to a valid
     /// JEXL expression.
     /// 
    public lazy var triggers: [String: String] = {
        self._variables.getStringMap("triggers")?.mergeWith(_defaults.triggers) ?? _defaults.triggers
    }()
    
    /// Not to be set by experiment.
    public lazy var experiment: String = {
        self._variables.getString("~~experiment") ?? _defaults.experiment
    }()
    
}
extension Messaging: FMLFeatureInterface {}


/// An enum to influence what should be displayed when a control message is
 /// selected.
public enum ControlMessageBehavior: String, CaseIterable, Codable {
    
    /// The next eligible message should be shown.
    case showNextMessage = "show-next-message"
    
    /// The surface should show no message.
    case showNone = "show-none"
    

    public static func enumValue(_ s: String?) -> ControlMessageBehavior? {
        guard let s = s else {
            return nil
        }
        return ControlMessageBehavior(rawValue: s)
    }
}


/// For messaging, we would like to have a message tell us which surface its
 /// associated with. This is a label that matches across both Android and iOS.
 /// 
public enum MessageSurfaceId: String, CaseIterable, Codable {
    
    /// A message has NOT declared its target surface.
    case unknown = "Unknown"
    
    /// This is a microsurvey that appears on top of the bottom toolbar to the user.
    case microsurvey = "microsurvey"
    
    /// This is the card that appears at the top on the Firefox Home Page.
    case newTabCard = "new-tab-card"
    
    /// This is a local notification send to the user periodically with tips and
     /// updates.
    case notification = "notification"
    
    /// This is a full-page that appears providing a survey to the user.
    case survey = "survey"
    

    public static func enumValue(_ s: String?) -> MessageSurfaceId? {
        guard let s = s else {
            return nil
        }
        return MessageSurfaceId(rawValue: s)
    }
}

/// An object to describe a message. It uses human readable strings to describe
 /// the triggers, action and style of the message as well as the text of the
 /// message and call to action.
 /// 
public class MessageData: FMLObjectInterface {
    private let _variables: Variables
    private let _defaults: Defaults
    private let _prefs: UserDefaults?

    private init(variables: Variables = NilVariables.instance, prefs: UserDefaults? = nil, defaults: Defaults) {
        self._variables = variables
        self._defaults = defaults
        self._prefs = prefs
    }
    
    struct Defaults {
        let action: String?
        let actionParams: [String: String]
        let buttonLabel: String?
        let exceptIfAny: [String]
        let experiment: String?
        let isControl: Bool
        let microsurveyConfig: MicrosurveyConfig?
        let style: String
        let surface: MessageSurfaceId
        let text: String
        let title: String?
        let triggerIfAll: [String]
    }

    public convenience init(
        _ _variables: Variables = NilVariables.instance,
        _ _prefs: UserDefaults? = nil,
        action: String? = nil,
        actionParams: [String: String] = [:],
        buttonLabel: String? = nil,
        exceptIfAny: [String] = [],
        experiment: String? = nil,
        isControl: Bool = false,
        microsurveyConfig: MicrosurveyConfig? = nil,
        style: String = "DEFAULT",
        surface: MessageSurfaceId = .unknown,
        text: String = "",
        title: String? = nil,
        triggerIfAll: [String] = ["ALWAYS"]
    ) {
        self.init(variables: _variables, prefs: _prefs, defaults: Defaults(
            action: action,
            actionParams: actionParams,
            buttonLabel: buttonLabel,
            exceptIfAny: exceptIfAny,
            experiment: experiment,
            isControl: isControl,
            microsurveyConfig: microsurveyConfig,
            style: style,
            surface: surface,
            text: text,
            title: title,
            triggerIfAll: triggerIfAll))
    }

    enum CodingKeys: String, CodingKey {
        case action = "action"
        case actionParams = "action-params"
        case buttonLabel = "button-label"
        case exceptIfAny = "except-if-any"
        case experiment = "experiment"
        case isControl = "is-control"
        case microsurveyConfig = "microsurveyConfig"
        case style = "style"
        case surface = "surface"
        case text = "text"
        case title = "title"
        case triggerIfAll = "trigger-if-all"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(actionParams, forKey: .actionParams)
        try container.encode(buttonLabel, forKey: .buttonLabel)
        try container.encode(exceptIfAny, forKey: .exceptIfAny)
        try container.encode(experiment, forKey: .experiment)
        try container.encode(isControl, forKey: .isControl)
        try container.encode(microsurveyConfig, forKey: .microsurveyConfig)
        try container.encode(style, forKey: .style)
        try container.encode(surface.rawValue, forKey: .surface)
        try container.encode(text, forKey: .text)
        try container.encode(title, forKey: .title)
        try container.encode(triggerIfAll, forKey: .triggerIfAll)
    }

    /// The name of a deeplink URL to be opened if the button is clicked.
     /// 
    public lazy var action: String? = {
        self._variables.getString("action") ?? _defaults.action
    }()
    
    /// Query parameters appended to the deeplink action URL
    public lazy var actionParams: [String: String] = {
        self._variables.getStringMap("action-params")?.mergeWith(_defaults.actionParams) ?? _defaults.actionParams
    }()
    
    /// The text on the button. If no text is present, the whole message is
     /// clickable.
     /// 
    public lazy var buttonLabel: String? = {
        self._variables.getText("button-label") ?? _defaults.buttonLabel.map { self._variables.resourceBundles.getString(named: $0) ?? $0 }
    }()
    
    /// A list of strings corresponding to targeting expressions. If any of these
     /// expressions evaluate to `true`, the message will not be eligible.
     /// 
    public lazy var exceptIfAny: [String] = {
        self._variables.getStringList("except-if-any") ?? _defaults.exceptIfAny
    }()
    
    /// The experiment slug that this message is involved in.
    public lazy var experiment: String? = {
        self._variables.getString("experiment") ?? _defaults.experiment
    }()
    
    /// Indicates if this message is the control message, if true shouldn't be
     /// displayed
    public lazy var isControl: Bool = {
        self._variables.getBool("is-control") ?? _defaults.isControl
    }()
    
    /// Optional configuration data for a microsurvey.
    public lazy var microsurveyConfig: MicrosurveyConfig? = {
        self._variables.getVariables("microsurveyConfig")?.map(MicrosurveyConfig.create)._mergeWith(_defaults.microsurveyConfig) ?? _defaults.microsurveyConfig
    }()
    
    /// The style as described in a `StyleData` from the styles table.
     /// 
    public lazy var style: String = {
        self._variables.getString("style") ?? _defaults.style
    }()
    
    /// Each message will tell us the surface it is targeting with this.
    public lazy var surface: MessageSurfaceId = {
        self._variables.getString("surface")?.map(MessageSurfaceId.enumValue) ?? _defaults.surface
    }()
    
    /// The message text displayed to the user
    public lazy var text: String = {
        self._variables.getText("text") ?? self._variables.resourceBundles.getString(named: _defaults.text) ?? _defaults.text
    }()
    
    /// The title text displayed to the user
    public lazy var title: String? = {
        self._variables.getText("title") ?? _defaults.title.map { self._variables.resourceBundles.getString(named: $0) ?? $0 }
    }()
    
    /// A list of strings corresponding to targeting expressions. All named
     /// expressions must evaluate to true if the message is to be eligible to
     /// be shown.
     /// 
    public lazy var triggerIfAll: [String] = {
        self._variables.getStringList("trigger-if-all") ?? _defaults.triggerIfAll
    }()
    
}

public extension MessageData {
    func _mergeWith(_ defaults: MessageData?) -> MessageData {
        guard let defaults = defaults else {
            return self
        }
        return MessageData(variables: self._variables, prefs: self._prefs, defaults: defaults._defaults)
    }

    static func create(_ variables: Variables?) -> MessageData {
        return MessageData(variables ?? NilVariables.instance)
    }

    static func mergeWith(_ overrides: MessageData, _ defaults: MessageData) -> MessageData {
        return overrides._mergeWith(defaults)
    }
}

/// Attributes relating to microsurvey messaging.
 /// 
public class MicrosurveyConfig: FMLObjectInterface {
    private let _variables: Variables
    private let _defaults: Defaults
    private let _prefs: UserDefaults?

    private init(variables: Variables = NilVariables.instance, prefs: UserDefaults? = nil, defaults: Defaults) {
        self._variables = variables
        self._defaults = defaults
        self._prefs = prefs
    }
    
    struct Defaults {
        let icon: String
        let options: [String]
        let utmContent: String?
    }

    public convenience init(
        _ _variables: Variables = NilVariables.instance,
        _ _prefs: UserDefaults? = nil,
        icon: String = "lightbulbLarge",
        options: [String] = [],
        utmContent: String? = nil
    ) {
        self.init(variables: _variables, prefs: _prefs, defaults: Defaults(
            icon: icon,
            options: options,
            utmContent: utmContent))
    }

    enum CodingKeys: String, CodingKey {
        case icon = "icon"
        case options = "options"
        case utmContent = "utm-content"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(icon.encodableImageName, forKey: .icon)
        try container.encode(options, forKey: .options)
        try container.encode(utmContent, forKey: .utmContent)
    }

    /// The asset name in our bundle used as the icon shown in the survey.
    public lazy var icon: UIImage = {
        self._variables.getImage("icon") ?? self._variables.resourceBundles.getImageNotNull(named: _defaults.icon)
    }()
    
    /// The list of survey options to present to the user.
    public lazy var options: [String] = {
        self._variables.getTextList("options") ?? _defaults.options.map { self._variables.resourceBundles.getString(named: $0) ?? $0 }
    }()
    
    /// The name used to provide as the utm_content parameter for the privacy
     /// notice.
    public lazy var utmContent: String? = {
        self._variables.getString("utm-content") ?? _defaults.utmContent
    }()
    
}

public extension MicrosurveyConfig {
    func _mergeWith(_ defaults: MicrosurveyConfig?) -> MicrosurveyConfig {
        guard let defaults = defaults else {
            return self
        }
        return MicrosurveyConfig(variables: self._variables, prefs: self._prefs, defaults: defaults._defaults)
    }

    static func create(_ variables: Variables?) -> MicrosurveyConfig {
        return MicrosurveyConfig(variables ?? NilVariables.instance)
    }

    static func mergeWith(_ overrides: MicrosurveyConfig, _ defaults: MicrosurveyConfig) -> MicrosurveyConfig {
        return overrides._mergeWith(defaults)
    }
}

/// A group of properities (predominantly visual) to the describe style of the
 /// message.
 /// 
public class StyleData: FMLObjectInterface {
    private let _variables: Variables
    private let _defaults: Defaults
    private let _prefs: UserDefaults?

    private init(variables: Variables = NilVariables.instance, prefs: UserDefaults? = nil, defaults: Defaults) {
        self._variables = variables
        self._defaults = defaults
        self._prefs = prefs
    }
    
    struct Defaults {
        let maxDisplayCount: Int
        let priority: Int
    }

    public convenience init(
        _ _variables: Variables = NilVariables.instance,
        _ _prefs: UserDefaults? = nil,
        maxDisplayCount: Int = 5,
        priority: Int = 50
    ) {
        self.init(variables: _variables, prefs: _prefs, defaults: Defaults(
            maxDisplayCount: maxDisplayCount,
            priority: priority))
    }

    enum CodingKeys: String, CodingKey {
        case maxDisplayCount = "max-display-count"
        case priority = "priority"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(maxDisplayCount, forKey: .maxDisplayCount)
        try container.encode(priority, forKey: .priority)
    }

    /// How many sessions will this message be shown to the user before it is
     /// expired.
     /// 
    public lazy var maxDisplayCount: Int = {
        self._variables.getInt("max-display-count") ?? _defaults.maxDisplayCount
    }()
    
    /// The importance of this message. 0 is not very important, 100 is very
     /// important.
     /// 
    public lazy var priority: Int = {
        self._variables.getInt("priority") ?? _defaults.priority
    }()
    
}

public extension StyleData {
    func _mergeWith(_ defaults: StyleData?) -> StyleData {
        guard let defaults = defaults else {
            return self
        }
        return StyleData(variables: self._variables, prefs: self._prefs, defaults: defaults._defaults)
    }

    static func create(_ variables: Variables?) -> StyleData {
        return StyleData(variables ?? NilVariables.instance)
    }

    static func mergeWith(_ overrides: StyleData, _ defaults: StyleData) -> StyleData {
        return overrides._mergeWith(defaults)
    }
}

