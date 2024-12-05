import Foundation

extension FileManager {
    static let pages = directory.appendingPathComponent("pages")
    static let snapshots = directory.appendingPathComponent("snapshots")
    static let user = directory.item("user")
    static let tabs = pages.item("tabs")
    static let currentTab = pages.item("currentTab")
    static let favourites = pages.item("favourites")
    static let history = pages.item("history")
    static let unleash = directory.item("unleash")
    static let news = directory.item("news")

    private static let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

private extension URL {
    func item(_ name: String) -> URL {
        appendingPathComponent(name + ".ecosia")
    }
}
