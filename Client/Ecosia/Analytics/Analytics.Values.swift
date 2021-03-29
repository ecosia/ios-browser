import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
        browser,
        navigation,
        external,
        onboarding,
        migration
    }
    
    enum Label {
        enum Screen: String {
            case
            home,
            projects,
            news,
            more
        }
        
        enum Features: String {
            case
            favourites,
            history,
            tabs,
            settings
        }
        
        enum More: String {
            case
            counter,
            how_ecosia_works,
            financial_reports,
            shop,
            faq,
            settings,
            send_feedback,
            privacy,
            terms
        }
        
        enum Onboarding: String {
            case
            intro,
            callout_ads,
            callout_counter
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
        
        enum Share: String {
            case
            start,
            complete,
            send_to_files
        }
        
        enum Favourites: String {
            case
            add,
            open,
            edit,
            delete
        }
        
        enum History: String {
            case
            open,
            delete,
            delete_all
        }
        
        enum Tabs: String {
            case
            add,
            open,
            delete,
            delete_all
        }
        
        enum Onboarding: String {
            case
            view,
            close,
            finish
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
        new_tab
    }

    enum Migration: String {
        case
        tabs,
        favourites,
        history
    }
}
