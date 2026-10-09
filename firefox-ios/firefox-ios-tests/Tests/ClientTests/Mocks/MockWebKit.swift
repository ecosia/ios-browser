// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

// MARK: WKNavigationActionMock
class WKNavigationActionMock: WKNavigationAction {
    var overridenTargetFrame: WKFrameInfoMock?

    override var targetFrame: WKFrameInfo? {
        return overridenTargetFrame
    }
}

// MARK: WKFrameInfoMock
class WKFrameInfoMock: WKFrameInfo {
    private var overridenSecurityOrigin: WKSecurityOrigin?
    private var overridenWebView: WKWebView?
    private var overridenTargetFrame = false

    // Ecosia: Allocate via the objc runtime instead of a Swift initializer. WKFrameInfo's initializer is
    // unavailable, and on the iOS 26.5 SDK calling it (via subclass init -> super.init()) crashes the process,
    // which crashed every test that built a frame mock (WKFrameInfoExtensions, BrowserCoordinator,
    // PasswordGenerator, and formerly FormAutofill/WebViewNavigationHandler before those were synced to
    // upstream's mock-free APIs). This mirrors WKSecurityOriginMock.new below. (MOB-4384)
    class func new(webView: WKWebViewMock? = nil,
                   frameURL: URL? = nil,
                   isMainFrame: Bool? = false) -> WKFrameInfoMock {
        guard let instance = self.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
                as? WKFrameInfoMock
        else {
            fatalError("Could not allocate WKFrameInfoMock instance")
        }
        instance.overridenSecurityOrigin = WKSecurityOriginMock.new(frameURL)
        instance.overridenWebView = webView
        instance.overridenTargetFrame = isMainFrame ?? false
        return instance
    }

    override var isMainFrame: Bool {
        return overridenTargetFrame
    }

    override var securityOrigin: WKSecurityOrigin {
        return overridenSecurityOrigin ?? WKSecurityOriginMock.new(nil)
    }

    override var webView: WKWebView? {
        return overridenWebView
    }
}

// MARK: WKSecurityOriginMock
class WKSecurityOriginMock: WKSecurityOrigin {
    var overridenProtocol: String!
    var overridenHost: String!
    var overridenPort: Int!

    class func new(_ url: URL?) -> WKSecurityOriginMock {
        // Dynamically allocate a WKSecurityOriginMock instance because 
        // the initializer for WKSecurityOrigin is unavailable
        //  https://github.com/WebKit/WebKit/blob/52222cf447b7215dd9bcddee659884f704001827/Source/WebKit/UIProcess/API/Cocoa/WKSecurityOrigin.h#L40
        guard let instance = self.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
                as? WKSecurityOriginMock
        else {
            fatalError("Could not allocate WKSecurityOriginMock instance")
        }
        instance.overridenProtocol = url?.scheme ?? ""
        instance.overridenHost = url?.host ?? ""
        instance.overridenPort = url?.port ?? 0
        return instance
    }

    override var `protocol`: String { overridenProtocol }
    override var host: String { overridenHost }
    override var port: Int { overridenPort }
}

// MARK: WKWebViewMock
class WKWebViewMock: WKWebView {
    var overridenURL: URL

    init(_ url: URL) {
        self.overridenURL = url
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override var url: URL {
        return overridenURL
    }
}

// MARK: - WKScriptMessageMock
class WKScriptMessageMock: WKScriptMessage {
    let overridenBody: Any
    let overridenName: String
    let overridenFrameInfo: WKFrameInfo

    init(name: String, body: Any, frameInfo: WKFrameInfo) {
        overridenBody = body
        overridenName = name
        overridenFrameInfo = frameInfo
    }

    override var body: Any {
        return overridenBody
    }

    override var name: String {
        return overridenName
    }

    override var frameInfo: WKFrameInfo {
        return overridenFrameInfo
    }

    // Ecosia: decodeBody extension on WKScriptMessage removed in v147; replicate inline for tests
    func decodeBody<T: Decodable>(as type: T.Type) -> T? {
        if let dict = body as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            return try? JSONDecoder().decode(type, from: data)
        } else if let bodyString = body as? String,
                  let data = bodyString.data(using: .utf8) {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }
}
