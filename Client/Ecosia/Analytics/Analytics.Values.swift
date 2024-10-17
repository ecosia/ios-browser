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
        bookmarks
    }
    
    enum Label {
        enum Navigation: String {
            case
            inapp,
            projects,
            financialReports = "financial_reports",
            news,
            privacy,
            sendFeedback = "send_feedback",
            terms
        }
        
        enum NTP: String {
            case
            about,
            customize,
            topSites = "top_sites",
            impact,
            quickActions = "quick_actions",
            news,
            onboardingCard = "onboarding_card",
            climateCounter = "climate_counter"
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
        
        enum Menu: String {
            case
            bookmarks,
            copyLink = "copy_link",
            customizeHomepage = "customize_homepage",
            downloads,
            findInPage = "find_in_page",
            help,
            history,
            home,
            newTab = "new_tab",
            openInSafari = "open_in_safari",
            readingList = "reading_list",
            requestDesktopSite = "request_desktop_site",
            settings,
            zoom
        }
        
        enum MenuStatus: String {
            case
            bookmark,
            darkMode = "dark_mode",
            readingList = "reading_list",
            shortcut
        }
        
        enum Onboarding: String {
            case
            next,
            skip
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

        enum SeedCounter: String {
            case
            level,
            collect,
            click
        }
        
        enum NTPCustomization: String {
            case
            click,
            disable,
            enable
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
        tabs
    }

    enum ShareContent: String {
        case
        ntp,
        web,
        file
    }
}
