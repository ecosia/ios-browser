// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A reusable avatar component that displays user avatars with remote image loading
public struct EcosiaAvatar: View {
    private let avatarURL: URL?
    private let size: CGFloat
    private let placeholderImage: String

    public init(
        avatarURL: URL?,
        size: CGFloat = .ecosia.space._2l,
        placeholderImage: String = "avatar"
    ) {
        self.avatarURL = avatarURL
        self.size = size
        self.placeholderImage = placeholderImage
    }

    public var body: some View {
        Group {
            if let avatarURL = avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(let error):
                        let nsError = error as NSError
                        /*
                         Workaround for iOS AsyncImage bug (error -999 cancellation).
                         Retry once on cancellation: https://developer.apple.com/forums/thread/682498
                         */
                        if nsError.code == NSURLErrorCancelled {
                            AsyncImage(url: avatarURL) { retryPhase in
                                if let image = retryPhase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    placeholderView
                                }
                            }
                        } else {
                            placeholderView
                        }
                    @unknown default:
                        placeholderView
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .accessibilityLabel("User avatar")
            } else {
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
        Image(placeholderImage, bundle: .ecosia)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityLabel("Default avatar")
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAvatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            // With remote URL
            EcosiaAvatar(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                size: .ecosia.space._6l
            )

            // Without URL (placeholder)
            EcosiaAvatar(
                avatarURL: nil,
                size: .ecosia.space._6l
            )

            // Small size
            EcosiaAvatar(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                size: .ecosia.space._2l
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
