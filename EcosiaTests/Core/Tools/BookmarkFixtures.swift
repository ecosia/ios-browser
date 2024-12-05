import Foundation

enum BookmarkFixtures {
    enum Browser: String {
        case chrome, firefox, safari
    }

    case html(Browser), debugString(Browser)

    var value: String {
        switch self {
        case let .html(browser):
            return String(
                data: try! Data(contentsOf: Bundle.module.url(forResource: "import_input_bookmark_\(browser.rawValue)", withExtension: "html")!),
                encoding: .utf8
            )!.trimmingCharacters(in: .newlines)
        case let .debugString(browser):
            return String(
                data: try! Data(contentsOf: Bundle.module.url(forResource: "import_output_bookmark_\(browser.rawValue)", withExtension: "txt")!),
                encoding: .utf8
            )!.trimmingCharacters(in: .newlines)
        }
    }

    static var ecosiaExportedHtml: String {
        String(
            data: try! Data(contentsOf: Bundle.module.url(forResource: "export_bookmark_ecosia", withExtension: "html")!),
            encoding: .utf8
        )!.trimmingCharacters(in: .newlines)
    }
}
