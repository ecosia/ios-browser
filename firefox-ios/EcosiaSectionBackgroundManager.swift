import Foundation
import UIKit

/// Manages the background image used by Ecosia sections on the Homepage (NTP).
/// Supports three sources:
/// - Asset: bundled image from the asset catalog (e.g., "EcosiaNTPBackground")
/// - File: local file path (e.g., downloaded and persisted)
/// - Remote: URL to be downloaded and cached locally
final class EcosiaSectionBackgroundManager {
    enum Source: Equatable {
        case asset(name: String)
        case file(path: String)
        case remote(url: URL)
    }

    enum Notifications {
        static let backgroundDidChange = Notification.Name("EcosiaSectionBackgroundManager.backgroundDidChange")
    }

    static let shared = EcosiaSectionBackgroundManager()

    private let ioQueue = DispatchQueue(label: "EcosiaSectionBackgroundManager.io")
    private let cache = NSCache<NSString, UIImage>()

    // Persist the selected source (e.g., from Settings) so it survives restarts
    private let defaultsKey = "EcosiaSectionBackgroundManager.SelectedSource"

    // Current source (default to asset placeholder)
    private var _source: Source = .asset(name: "EcosiaNTPBackground")
    var source: Source {
        get { _source }
        set {
            guard _source != newValue else { return }
            _source = newValue
            persistSource(newValue)
            notifyChange()
        }
    }

    private init() {
        // Load persisted selection
        if let persisted = loadPersistedSource() {
            _source = persisted
        }
    }

    // MARK: - Public API

    /// Asynchronously loads the current image for the configured source.
    /// Falls back to nil if unavailable (callers should provide a fallback color).
    func loadCurrentImage(completion: @escaping (UIImage?) -> Void) {
        switch source {
        case .asset(let name):
            completion(UIImage(named: name))
        case .file(let path):
            ioQueue.async {
                let url = URL(fileURLWithPath: path)
                let img = UIImage(contentsOfFile: url.path)
                DispatchQueue.main.async { completion(img) }
            }
        case .remote(let url):
            // Try cached first
            if let cached = cache.object(forKey: url.absoluteString as NSString) {
                completion(cached)
                return
            }
            downloadRemote(url: url, completion: completion)
        }
    }

    /// Configure a new background source. This will notify observers (e.g., decoration view) to refresh.
    func setSource(_ newSource: Source) {
        self.source = newSource
    }

    // MARK: - Private helpers

    private func downloadRemote(url: URL, completion: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, let img = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            // Cache in-memory for quick reuse
            self.cache.setObject(img, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async { completion(img) }

            // Persist to disk so it’s available offline
            self.ioQueue.async {
                let fileURL = self.makeCacheFileURL(for: url)
                try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
                try? data.write(to: fileURL)
            }
        }
        task.resume()
    }

    private func makeCacheFileURL(for url: URL) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let filename = url.lastPathComponent.isEmpty ? "ecosia_ntp_bg" : url.lastPathComponent
        return caches.appendingPathComponent("Ecosia/NTPBackground/\(filename)")
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: Notifications.backgroundDidChange, object: nil)
    }

    // MARK: - Persistence

    private func persistSource(_ source: Source) {
        switch source {
        case .asset(let name):
            UserDefaults.standard.set(["type": "asset", "name": name], forKey: defaultsKey)
        case .file(let path):
            UserDefaults.standard.set(["type": "file", "path": path], forKey: defaultsKey)
        case .remote(let url):
            UserDefaults.standard.set(["type": "remote", "url": url.absoluteString], forKey: defaultsKey)
        }
    }

    private func loadPersistedSource() -> Source? {
        guard let dict = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String],
              let type = dict["type"] else { return nil }
        switch type {
        case "asset":
            if let name = dict["name"], !name.isEmpty { return .asset(name: name) }
        case "file":
            if let path = dict["path"], !path.isEmpty { return .file(path: path) }
        case "remote":
            if let urlString = dict["url"], let url = URL(string: urlString) { return .remote(url: url) }
        default:
            break
        }
        return nil
    }
}
