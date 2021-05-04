import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
        browser,
        external,
        migration,
        navigation,
        onboarding
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
            privacy,
            sendFeedback = "send_feedback",
            terms
        }
        
        enum Browser: String {
            case
            newTab = "new_tab",
            favourites,
            history,
            tabs,
            settings,
            shareContent = "share_content"
        }
    }
    
    enum Action: String {
        case
        view,
        open,
        receive,
        error,
        completed,
        success
        
        enum Activity: String {
            case
            launch,
            resume
        }
        
        enum Browser: String {
            case
            add,
            open,
            edit,
            delete,
            delete_all = "delete_all",
            start,
            complete,
            sendToFiles = "send_to_files"
        }

        enum Promo: String {
            case
            view,
            click,
            close
        }
    }
    
    enum Property: String {
        case
        home,
        menu,
        toolbar
    }

    enum Migration: String {
        case
        tabs,
        favourites,
        history
    }
}
