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
        case allRegions = "All regions"
        case autocomplete = "Autocomplete"
        case closeAll = "Close all"
        case daysAgo = "%@ days ago"
        case ecosiaRecommends = "Ecosia recommends"
        case estimatedImpact = "Estimated impact"
        case estimatedTrees = "Estimated trees"
        case exploreEcosia = "Explore Ecosia"
        case faqs = "FAQs"
        case financialReports = "Financial reports"
        case forceDarkMode = "Force Dark Mode"
        case turnOffDarkMode = "Turn off Dark Mode"
        case getStarted = "Get started"
        case home = "Home"
        case howEcosiaWorks = "How Ecosia works"
        case invalidReferralLink = "Invalid referral link!"
        case invalidReferralLinkMessage = "Your referral link is wrong or not valid for you. Please check it and try again."
        case invertColors = "Invert website colors"
        case inviteFriends = "Invite friends"
        case inviteFriendsSpotlight = "Help plant trees by inviting friends"
        case keepUpToDate = "Keep up to date with the latest news from our projects and more"
        case youveContributed = "You’ve contributed to plant a tree with your friend!"
        case learnMore = "Learn more"
        case linkAlreadyUsedTitle = "Link already used"
        case linkAlreadyUsedMessage = "You can only use an invitation link once."
        case makeEcosiaYourDefaultBrowser = "Make Ecosia your default browser"
        case moderate = "Moderate"
        case seeMoreNews = "See more news"
        case multiplyImpact = "Multiply impact"
        case yourImpact = "Your impact"
        case yourInvites = "Your invites"
        case growingTogether = "Growing together"
        case myImpactDescription = "This is the estimated number of trees you have contributed to planting by using Ecosia."
        case mySearches = "My searches"
        case myTrees = "My trees"
        case networkError = "Network error!"
        case new = "New"
        case noConnectionMessage = "We couldn't verify your link. Please check your internet connection and try again."
        case noConnectionNSURLErrorTitle = "No connection"
        case noConnectionNSURLErrorMessage = "Please check your internet connection and try again"
        case noConnectionNSURLErrorRefresh = "Refresh"
        case off = "Off"
        case onAverageItTakes = "On average it takes around 45 searches to plant a tree"
        case openInSafari = "Open In Safari"
        case personalizedResults = "Personalized results"
        case plantTreesWhile = "Plant trees while you browse the web"
        case privacy = "Privacy"
        case privateTab = "Private"
        case privateEmpty = "Ecosia won’t remember the pages you visited, your search history or your autofill information once you close a tab. Your searches still contribute to trees."
        case relevantResults = "Relevant results based on past searches"
        case referrals = "%d referral(s)"
        case referralAccepted = "A friend accepted your invitation and each of you will help plant 1 tree!"
        case referralsAccepted = "%@ friends accepted your invitation and each of you will help plant %@ trees!"
        case safeSearch = "Safe search"
        case search = "Search"
        case searches = "%d search(es)"
        case searchAndPlant = "Search the web to plant trees..."
        case searchRegion = "Search region"
        case sendFeedback = "Send feedback"
        case shownUnderSearchField = "Shown under the search field"
        case startPlanting = "Plant your first tree"
        case stories = "Stories"
        case strict = "Strict"
        case tapCounter = "Tap your tree counter to share Ecosia with friends and plant more trees"
        case terms = "Terms and conditions"
        case today = "Today"
        case togetherWeCan = "Together, we can reforest our planet. Tap your counter to spread the word!"
        case totalEcosiaTrees = "Total Ecosia trees"
        case treesPlural = "%d tree(s)"
        case trees = "TREES"
        case treesUpdate = "Trees update"
        case treesPlantedWithEcosia = "TREES PLANTED WITH ECOSIA"
        case useTheseCompanies = "Start using these green companies to plant more trees and become more sustainable"
        case version = "Version %@"
        case viewMyImpact = "View my impact"
        case weUseTheProfit = "We use the profit from your searches to plant trees where they are needed most"
        case helpUsImprove = "Help us improve our new app"
        case letUsKnowWhat = "Let us know what you like, dislike, and want to see in the future."
        case shareYourFeedback = "Share your feedback"
        case sitTightWeAre = "Sit tight, we are getting ready for you…"
        case weHitAGlitch = "We hit a glitch"
        case weAreMomentarilyUnable = "We are momentarily unable to load all of your settings."
        case continueMessage = "Continue"
        case retryMessage = "Retry"
        case setAsDefaultBrowser = "Set Ecosia as default browser"
        case linksFromWebsites = "Links from websites, emails or messages will automatically open in Ecosia."
        case showTopSites = "Show Top Sites"
        case helpYourFriendsBecome = "Help your friends become climate active and plant trees together"
        case friendsJoined = "%d friend(s) joined"
        case acceptedInvites = "%d accepted invite(s)"
        case invitingAFriend = "Inviting a friend"
        case inviteYourFriends = "Invite your friends"
        case sendAnInvite = "Send an invite with your unique invitation link"
        case theyDownloadTheApp = "They download the Ecosia app"
        case viaTheAppStore = "Via the AppStore (invites for Android are coming soon)"
        case theyOpenYourInviteLink = "They open your invite link"
        case yourFriendClicks = "Your friend clicks on your unique link from the invite message"
        case eachOfYouHelpsPlant = "Each of you helps plant a tree"
        case whenAFriendUses = "When a friend uses your invite link, you both plant an extra tree"
        case noBookmarksYet = "No bookmarks yet"
        case AddYourFavoritePages = "Add your favorite pages to your bookmarks and they will appear here"
        case noArticles = "No articles on your reading list"
        case openArticlesInReader = "Open articles in Reader View by tapping the page icon in the address bar"
        case saveArticlesToReader = "Save articles to your Reading list by tapping on ‘Add to Reading List’ in the options while in Reader View"
        case noHistory = "No history"
        case websitesYouHave = "Websites you’ve recently visited will show up here"
        case noDownloadsYet = "No downloads yet"
        case whenYouDownloadFiles = "When you download files they will show up here"
        case checkThisOut = "Check this out: Ecosia plants trees every time you search the web! 🌳\nJoin me and %@+ others and start planting today."
        case downloadTheApp = "1. Download the app:"
        case useMyInviteLink = "2. Use my ✨ invite link ✨ and we will both plant an extra tree 🌳\n(Android coming soon):"
        case seeWhatsNew = "See what's new"
        case ecosiaNewLook = "Ecosia has a new look, and we added an easy way for you to track your trees."
        case discoverEcosia = "Discover the new Ecosia"
        case trackYourProgress = "Track your progress and get insights about your impact"
        case theSimplestWay = "The simplest way to be \n climate-active every day while \n browsing the web"
        case skipWelcomeTour = "Skip welcome tour"
        case aBetterPlanet = "A better planet with every search"
        case searchTheWeb = "Search the web and plant trees with the fast, free, and full-featured Ecosia browser"
        case hundredPercentOfProfits = "100% of profits for the planet"
        case weUseAllOurProfits = "We use all our profits for climate action, such as planting trees and generating solar energy."
        case collectiveAction = "Collective action starts here"
        case join15Million = "Join 15 million people growing the right trees in the right places."
        case weWantTrees = "We want your trees, not your data"
        case weDontCreateAProfile = "We don’t create a profile of you and will never sell your details to advertisers."
        case skip = "Skip"
        case treesPlanted = "Trees planted"
        case sustainableShoes = "sustainable shoes"
        case before = "Before ..."
        case after = "After"
        case treesPlantedByTheCommunity = "Trees planted by the Ecosia community"
        case activeProjects = "Active projects"
        case countries = "Countries"
        case finishTour = "Start Planting"
        case treesPlantedPlural = "Tree(s) planted"
        case howItWorks = "How it works"
        case friendInvitesPlural = "%d friend invite(s)"
        case openSettings = "Open settings"
        case maybeLater = "Maybe later"
        case openAllLinks = "Open all links with Ecosia to plant more trees"
        case growYourImpact = "Grow your impact with your web searches"
        case groupYourImpact = "Group your impact"
        case getATreeWithEveryFriend = "Get a tree with every friend who joins. They get one too!"
        case aboutEcosia = "About Ecosia"
        case learnHowEcosia = "Learn how Ecosia turns ad revenue from your searches into trees planted around the world."
        case seeHowMuchMoney = "See how much money was generated by your searches each month, and how much we used to plant trees."
        case discoverWhereWe = "Discover where we plant trees, and find out how our tree planting projects across the globe are doing."
        case learnHowWe = "Learn how we protect your privacy by not creating a profile of you, never selling your data to advertisers and more."
        case findAnswersTo = "Find answers to popular questions like how Ecosia neutralizes CO2 emissions and what it means to be a social business."
        case customization = "Customization"
        case clearAll = "Clear all"
        case searchBarHint = "To make entering info easier, the toolbar can be set to the bottom of the screen"
        case buyTrees = "Buy trees in the Ecosia tree store to delight a friend - or treat yourself"
        case plantTreesAndEarn = "Plant trees and earn eco-friendly rewards with Treecard"
        case sponsored = "Sponsored"
        case inviteYourFriendsToCheck = "Invite your friends to check out Ecosia. When they join, you both plant an extra tree."
        case sharingYourLink = "Sharing your link"
        case copy = "Copy"
        case moreSharingMethods = "More sharing methods"
        case copied = "Copied!"
        case plantTreesWithMe = "Plant trees with me on Ecosia"
        case ecosiaLogoAccessibilityLabel = "Ecosia logo"
        case done = "Done"
        case findInPage = "Find in page"
    }
}