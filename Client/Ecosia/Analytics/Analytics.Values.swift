import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
        abTest = "ab_Test",
        browser,
        pushNotificationConsent = "push_notification_consent",
        external,
        migration,
        navigation,
        onboarding,
        intro,
        invitations,
        ntp,
        menu,
        menuStatus = "menu_status",
        settings,
        bookmarks,
        climateCounter = "climate_counter"
    }
    
    enum Label {
        enum Navigation: String {
            case
            inapp,
            projects,
            counter,
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
        
        enum NTP: String {
            case
            about,
            customize,
            topSites = "top_sites",
            impact,
            quickActions = "quick_actions",
            news,
            about,
            topSites = "top_sites"
            seedCounter = "seed_counter"
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
        
        enum Bookmarks: String {
            case
            importFunctionality = "import_functionality",
            learnMore = "learn_more",
            `import`
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
        display,
        enable,
        disable,
        dismiss,
        search
        
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
        
        enum APNConsent: String {
            case
            view,
            skip,
            deny,
            allow,
            dismiss
        }
        
        enum Bookmarks: String {
            case
            `import`
        }
        
        enum TopSite: String {
            case
            click,
            openNewTab = "open_new_tab",
            openPrivateTab = "open_private_tab",
            pin,
            remove,
            unpin
        }
    }
    
    enum Property {
        case
        home,
        menu,
        toolbar
        
        var rawValue: String {
            switch self {
            case .home:
                return "home"
            case .menu:
                return "menu"
            case .toolbar:
                return "toolbar"
            }
        }
        
        enum Library: String {
            case
            bookmarks,
            downloads,
            history,
            readingList = "reading_list"
        }
        
        enum TopSite: String {
            case
            `default`,
            mostVisited = "most_visited",
            pinned
        }
        
        enum Bookmarks: String {
            case
            `import`,
            export,
            emptyState = "empty_state",
            success,
            error
        }
        
        enum OnboardingPage: String, CaseIterable {
            case
            start,
            search,
            profits,
            action,
            privacy,
            greenSearch = "green_search",
            transparentFinances = "transparent_finances"
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
