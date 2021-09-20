/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    static func localized(_ forKey: Key) -> String {
        localized(forKey.rawValue)
    }
    
    static func localized(_ string: String) -> String {
        NSLocalizedString(string, tableName: "Ecosia", comment: "")
    }

    static func localizedPlural(_ forKey: Key, num: Int) -> String {
        return String(format: NSLocalizedString(forKey.rawValue, tableName: "Plurals", comment: ""), num)
    }
    
    enum Key: String {
        case autocomplete = "Autocomplete"
        case closeAll = "Close all"
        case daysAgo = "%@ days ago"
        case ecosiaRecommends = "Ecosia recommends"
        case estimatedImpact = "Estimated impact"
        case estimatedTrees = "Estimated trees"
        case exploreEcosia = "Explore Ecosia"
        case faq = "FAQ"
        case financialReports = "Financial reports"
        case forceDarkMode = "Force Dark Mode"
        case getStarted = "Get started"
        case howEcosiaWorks = "How Ecosia works"
        case invalidReferralLink = "Invalid referral link!"
        case invalidReferralLinkMessage = "Your referral link is wrong or not valid for you. Please check it and try again."
        case invertColors = "Invert website colors"
        case inviteFriends = "Invite friends"
        case inviteFriendsSpotlight = "Invite friends to plant even more trees"
        case keepUpToDate = "Keep up to date with the latest news from our projects and more"
        case keepGoing = "Keep going by browsing the web with Ecosia and sharing the app with friends!"
        case learnMore = "Learn more"
        case makeEcosiaYourDefault = "Make Ecosia your default"
        case moderate = "Moderate"
        case more = "More"
        case multiplyImpact = "Multipy impact"
        case myImpact = "My Impact"
        case myImpactDescription = "This is the estimated number of trees you have contributed to planting by using Ecosia."
        case mySearches = "My searches"
        case myTrees = "My trees"
        case networkError = "Network error!"
        case new = "New"
        case noConnectionMessage = "We couldn't verify your link. Please check your internet connection and try again."
        case off = "Off"
        case onAverageItTakes = "On average it takes around 45 searches to plant a tree"
        case personalizedResults = "Personalized results"
        case plantTreesWhile = "Plant trees while you browse the web"
        case privacy = "Privacy"
        case privateTab = "Private"
        case privateEmpty = "Ecosia won’t remember the pages you visited, your search history or your autofill information once you close a tab. Your searches still contribute to trees."
        case relevantResults = "Relevant results based on past searches"
        case referrals = "%d referral(s)"
        case referralAccepted = "A friend accepted your invitation and we'll plant 1 tree for each of you!"
        case referralsAccepted = "%@ friends accepted your invitation and you helped plant a total of %@ trees!"
        case safeSearch = "Safe search"
        case search = "Search"
        case searches = "%d search(es)"
        case searchAndPlant = "Search the web to plant trees..."
        case searchRegion = "Search region"
        case sendFeedback = "Send feedback"
        case shop = "Shop"
        case shownUnderSearchField = "Shown under the search field"
        case startPlanting = "Start your tree planting journey"
        case stories = "Stories"
        case strict = "Strict"
        case tapCounter = "Tap your tree counter to share Ecosia with friends and plant more trees"
        case terms = "Terms and conditions"
        case today = "Today"
        case togetherWeCan = "Together, we can reforest our planet. Tap your counter to spread the word!"
        case totalEcosiaTrees = "Total Ecosia trees"
        case treesPlural = "%d tree(s)"
        case trees = "TREES"
        case treesPlantedWithEcosia = "TREES PLANTED WITH ECOSIA"
        case useTheseCompanies = "Start using these green companies to plant more trees and become more sustainable"
        case version = "Version %@"
        case viewMyImpact = "View my impact"
        case weUseTheProfit = "We use the profit from your searches to plant trees where they are needed most"
        case websitesWillAlwaysOpen = "Websites will always open with Ecosia, planting even more trees"
        case helpUsImprove = "Help us improve our new app"
        case letUsKnowWhat = "Let us know what you like, dislike, and want to see in the future."
        case shareYourFeedback = "Share your feedback"
        case sitTightWeAre = "Sit tight, we are getting ready for you…"
        case weHitAGlitch = "We hit a glitch"
        case weAreMomentarilyUnable = "We are momentarily unable to load all of your settings."
        case continueMessage = "Continue"
        case welcomeToTheNewEcosia = "Welcome to the new Ecosia app!"
        case weHaveDoneSome = "We've done some re-arranging to make it easier for you to browse the web and plant trees with Ecosia."
        case takeALook = "Take a look"
        case setAsDefaultBrowser = "Set Ecosia as default browser"
        case linksFromWebsites = "Links from websites, emails or messages will automatically open in Ecosia."
        case showTopSites = "Show Top Sites"
        case everyTimeYouInvite = "Every time a friend accepts your invitation, you’ll contribute to plant extra trees."
        case successfulInvites = "%d successful invite(s)"
        case invitingAFriend = "Inviting a friend"
        case shareYourInvitation = "Share your invitation link"
        case viaEmailText = "via email, text message or social media"
        case yourFriendOpens = "Your friend opens your link"
        case afterInstallingTheApp = "after installing the app on an iPhone"
        case eachOfYouContribute = "Each of you contributes to planting a tree"
        case forEverySuccessful = "for every successful friend invite"
    }
}
