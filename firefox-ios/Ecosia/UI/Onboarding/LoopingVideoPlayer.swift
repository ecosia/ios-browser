// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVKit
import Combine
import SwiftUI

class VideoPlayerView: UIView {
    let playerLayer = AVPlayerLayer()

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let playerLayer = layer as? AVPlayerLayer {
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = bounds
        }
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    var onReady: (() -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = VideoPlayerView()

        // TODO: Check effect on app size and reduce the video
        guard let videoURL = Bundle.ecosia.url(forResource: videoName, withExtension: "mov") else {
            // Fallback to static image if video not found
            let imageView = UIImageView(image: .init(named: "forest", in: .ecosia, with: nil))
            imageView.contentMode = .scaleAspectFill
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(imageView)
            // Trigger onReady immediately for fallback
            DispatchQueue.main.async {
                onReady?()
            }
            return view
        }

        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)

        if let playerLayer = view.layer as? AVPlayerLayer {
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
        }

        // Store references in coordinator
        context.coordinator.player = player
        context.coordinator.view = view
        context.coordinator.onReady = onReady

        // Monitor player status
        context.coordinator.statusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .readyToPlay:
                    player.play()
                    context.coordinator.onReady?()
                case .failed:
                    // Call onReady even on failure to prevent animations from never starting
                    context.coordinator.onReady?()
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }

        // Monitor buffer status
        let bufferObserver = playerItem.publisher(for: \.isPlaybackBufferFull)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // Buffer monitoring
            }

        context.coordinator.bufferObserver = bufferObserver

        // Loop video when it ends
        context.coordinator.loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // View updates handled by layoutSubviews
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var player: AVPlayer?
        var view: UIView?
        var loopObserver: NSObjectProtocol?
        var statusObserver: AnyCancellable?
        var bufferObserver: AnyCancellable?
        var onReady: (() -> Void)?

        deinit {
            player?.pause()
            if let observer = loopObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            statusObserver?.cancel()
            bufferObserver?.cancel()
        }
    }
}
