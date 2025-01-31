import Foundation
@testable import Ecosia

struct User5_3: Codable {
    var install: Date?
    var news: Date?
    var analyticsId = UUID()
    var marketCode = Local.make(for: .current)
    var adultFilter = AdultFilter.moderate
    var autoComplete = true
    var firstTime = true
    var personalized: Bool? = false
    var topSites: Bool? = true
    var migrated: Bool? = false
    var id: String?
    var treeCount = 0
    var state = [String: String]()

    init() {
        install = .init()
    }

    enum Key: String {
        case
        welcomeScreen
    }
}
