// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WebKit
import Common

/// A modal view that displays web content in a WebView with navigation controls
@available(iOS 16.0, *)
public struct EcosiaWebViewModal: View {
    private let url: URL
    private let windowUUID: WindowUUID
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    @State private var theme = EcosiaWebViewModalTheme()
    @State private var webView: WKWebView?
    @State private var isLoading = true
    @State private var pageTitle = ""
    @State private var hasError = false
    @State private var errorMessage = ""

    public init(url: URL, windowUUID: WindowUUID) {
        self.url = url
        self.windowUUID = windowUUID
    }

    public var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        if hasError {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(theme.brandPrimaryColor)
                                    .accessibilityLabel(String.localized(.errorIcon))

                                Text(String.localized(.failedToLoadPage))
                                    .font(.headline)
                                    .foregroundColor(theme.brandPrimaryColor)

                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button(String.localized(.tryAgain)) {
                                    hasError = false
                                    isLoading = true
                                    let request = URLRequest(url: url)
                                    webView?.load(request)
                                }
                                .foregroundColor(theme.brandPrimaryColor)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            WebViewRepresentable(
                                url: url,
                                webView: $webView,
                                isLoading: $isLoading,
                                pageTitle: $pageTitle,
                                hasError: $hasError,
                                errorMessage: $errorMessage
                            )

                            if isLoading {
                                theme.backgroundColor
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                ProgressView()
                                    .scaleEffect(1.2)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String.localized(.close)) {
                        dismiss()
                    }
                    .foregroundColor(theme.brandPrimaryColor)
                    .accessibilityIdentifier("close_webview_modal_button")
                }
            }
        }
        .ecosiaThemed(windowUUID, $theme)
    }
}

/// UIViewRepresentable wrapper for WKWebView
@available(iOS 16.0, *)
private struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    @Binding var hasError: Bool
    @Binding var errorMessage: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        self.webView = webView

        var request = URLRequest(url: url)
        request.timeoutInterval = 30.0 // 30 second timeout
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.hasError = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.pageTitle = webView.title ?? ""
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.hasError = true
            parent.errorMessage = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.hasError = true
            parent.errorMessage = error.localizedDescription
        }
    }
}

/// Theme configuration for EcosiaWebViewModal
@available(iOS 16.0, *)
public struct EcosiaWebViewModalTheme: EcosiaThemeable {
    public var backgroundColor = Color.white
    public var brandPrimaryColor = Color.blue

    public init() {}

    public mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.layer1)
        brandPrimaryColor = Color(theme.colors.ecosia.brandPrimary)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaWebViewModal_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaWebViewModal(
            url: URL(string: "https://support.ecosia.org/article/844-seed-counter")!,
            windowUUID: .XCTestDefaultUUID
        )
    }
}
#endif
