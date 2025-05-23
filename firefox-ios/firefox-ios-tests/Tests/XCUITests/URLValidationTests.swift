// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class URLValidationTests: BaseTestCase {
    let urlTypes = ["www.mozilla.org", "www.mozilla.org/", "https://www.mozilla.org", "www.mozilla.org/en", "www.mozilla.org/en-",
                    "www.mozilla.org/en-US", "https://www.mozilla.org/", "https://www.mozilla.org/en", "https://www.mozilla.org/en-US"]
    let urlHttpTypes = ["http://example.com", "http://example.com/"]
    let urlField = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.UrlBar.url]

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].tap()
        scrollToElement(app.tables.switches["FirefoxSuggestShowNonSponsoredSuggestions"])
        app.tables.switches["FirefoxSuggestShowNonSponsoredSuggestions"].tap()
        navigator.goto(NewTabScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2460854
    // Smoketest
    func testDifferentURLTypes() {
        for url in urlTypes {
            navigator.openURL(url)
            waitUntilPageLoad()
            mozWaitForElementToExist(app.otherElements.staticTexts["Welcome to Mozilla"])
            mozWaitForElementToExist(app.buttons["Menu"])
            // Getting the current system locale ex:- en-US
            var locale = Locale.preferredLanguages[0]
            // Only the below url suffixes should lead to en-US website
            if url.hasSuffix("en") || url.hasSuffix("en-") || url.hasSuffix("en-US") {
                locale = "en-US"
            }
            mozWaitForValueContains(urlField, value: "www.mozilla.org/\(locale)/")
            clearURL()
        }

        for url in urlHttpTypes {
            navigator.openURL(url)
            waitUntilPageLoad()
            mozWaitForElementToExist(app.otherElements.staticTexts["Example Domain"])
            mozWaitForValueContains(urlField, value: "example.com/")
            clearURL()
        }
    }

    private func clearURL() {
        if iPad() {
            navigator.goto(URLBarOpen)
            app.buttons["Clear text"].waitAndTap()
        }
    }
}
