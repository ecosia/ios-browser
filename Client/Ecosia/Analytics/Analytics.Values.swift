import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
        abTest = "ab_Test",
        browser,
        external,
        migration,
        navigation,
        onboarding,
        intro,
        invitations,
        ntp,
        menu,
        menuStatus = "menu_status",
        settings
    }
    
    enum Label {
        enum Navigation: String {
            case
            home,
            projects,
            counter,
            howEcosiaWorks = "how_ecosia_works",
            financialReports = "financial_reports",
            shop,
            faq,
            news,
            next,
            privacy,
            sendFeedback = "send_feedback",
            skip,
            terms,
            treecard,
            treestore
        }
        
        enum Browser: String {
            case
            favourites,
            history,
            tabs,
            settings,
            newTab = "new_tab",
            blockImages = "block_images",
            searchbar = "searchbar"
        }
    }
    
    enum Action: String {
        case
        view,
        open,
        receive,
        error,
        completed,
        success,
        retry,
        send,
        claim,
        click,
        change,
        display
        
        enum Activity: String {
            case
            launch,
            resume
        }
        
        enum Browser: String {
            case
            open,
            start,
            complete,
            enable,
            disable
        }

        enum Promo: String {
            case
            view,
            click,
            close
        }
    }
    
    enum Property {
        case
        home,
        menu,
        toolbar,
        screenName(Int)
        
        var rawValue: String {
            switch self {
            case .home:
                return "home"
            case .menu:
                return "menu"
            case .toolbar:
                return "toolbar"
            case .screenName(let page):
                return OnboardingPage.allCases[page].rawValue
            }
        }
        
        enum TopSite: String {
            case
            blog,
            privacy,
            financialReports = "financial_reports",
            howEcosiaWorks = "how_ecosia_works"
        }
        
        enum OnboardingPage: String, CaseIterable {
            case
            start,
            search,
            profits,
            action,
            privacy
        }
    }

    enum Migration: String {
        case
        tabs,
        favourites,
        history,
        exception
    }

    enum ShareContent: String {
        case
        ntp,
        web,
        file
    }
}
