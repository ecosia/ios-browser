// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that loads and caches remote images
/// Provides smooth transitions and persistent caching across view reloads
@available(iOS 16.0, *)
struct EcosiaCachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let transition: AnyTransition

    @StateObject private var loader = ImageCacheLoader()

    init(
        url: URL?,
        transition: AnyTransition = .opacity,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.transition = transition
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            // Placeholder layer
            if loader.image == nil {
                placeholder()
                    .transition(transition)
            }

            // Loaded image layer
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
                    .transition(transition)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: loader.image != nil)
        .task(id: url) {
            if let url = url {
                await loader.loadImage(from: url)
            }
        }
    }
}

/// Image cache loader with NSCache-based memory caching
@MainActor
final class ImageCacheLoader: ObservableObject {
    @Published var image: UIImage?

    private static let cache = NSCache<NSURL, UIImage>()
    private var currentTask: Task<Void, Never>?

    deinit {
        currentTask?.cancel()
    }

    func loadImage(from url: URL) async {
        // Cancel any existing task
        currentTask?.cancel()

        // Check cache first
        if let cachedImage = Self.cache.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }

        // Load from network with retry on cancellation
        await loadImageWithRetry(from: url)
    }

    private func loadImageWithRetry(from url: URL, isRetry: Bool = false) async {
        currentTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                if let loadedImage = UIImage(data: data) {
                    // Cache the image
                    Self.cache.setObject(loadedImage, forKey: url as NSURL)
                    self.image = loadedImage
                }
            } catch {
                let nsError = error as NSError

                /*
                 Workaround for iOS AsyncImage bug (error -999 cancellation).
                 Retry once on cancellation: https://developer.apple.com/forums/thread/682498
                 */
                if nsError.code == NSURLErrorCancelled && !isRetry {
                    EcosiaLogger.accounts.debug("Image load cancelled, retrying once")
                    await loadImageWithRetry(from: url, isRetry: true)
                } else if !Task.isCancelled {
                    EcosiaLogger.accounts.debug("Failed to load avatar image: \(error.localizedDescription)")
                }
            }
        }

        await currentTask?.value
    }
}
