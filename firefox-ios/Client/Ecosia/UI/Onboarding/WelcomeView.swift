// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import AVKit
import Combine
import Common
import Ecosia

struct WelcomeView: View {
    @State private var animationPhase: AnimationPhase = .initial
    @State private var transitionMaskScale: CGFloat = 0.0
    @State private var transitionMaskHeight: CGFloat = 200.0
    @State private var transitionMaskWidth: CGFloat = 200.0
    @State private var welcomeTextOpacity: Double = 0.0
    @State private var logoOffset: CGFloat = 0.0
    @State private var welcomeTextOffset: CGFloat = 0.0
    @State private var bodyOpacity: Double = 0.0
    @State private var showRoundedBackground: Bool = false
    @State private var backgroundOpacity: Double = 1.0
    @State private var theme = WelcomeViewTheme()

    let windowUUID: WindowUUID
    let onFinish: () -> Void

    enum AnimationPhase {
        case initial
        case phase1Complete
        case phase2Complete
        case phase3Complete
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Matching Launch Screen background
            Color(.systemBackground)
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            // Video background (clipped to transition mask)
            if showRoundedBackground {
                LoopingVideoPlayer(videoName: "welcome_background")
                    .ignoresSafeArea()
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                            .frame(height: transitionMaskHeight)
                            .frame(maxWidth: transitionMaskWidth)
                            .scaleEffect(transitionMaskScale, anchor: .center)
                    )
            }
            
            // TODO: Add black gradient behind logo and body for readibility

            // Logo container
            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.contentTextColor)
                    .multilineTextAlignment(.center)
                    .opacity(welcomeTextOpacity)
                    .offset(y: welcomeTextOffset)
                
            // TODO: Adjust spacing with offsets
            // TODO: Make dynamic offsets depending on screen size
            // Can the animation be done without hardcoded offsets? Maybe start and end position?

                Image("ecosiaLogoLaunch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 112, height: 28)
                    .offset(y: logoOffset)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Ecosia.logo)
            }
            // TODO: Make sure logo matches launch screen exactly
            .frame(maxWidth: transitionMaskWidth)
            .ignoresSafeArea(edges: .vertical)

            // Content
            if animationPhase.isPhase3 {
                VStack {
                    Spacer()

                    Text("Real change at your fingertips")
                        .font(.ecosiaFamilyBrand(size: .ecosia.font._6l))
                        .foregroundStyle(theme.contentTextColor)
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: 20)

                    Text("Join 20 million people making a difference every day")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.contentTextColor)
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: 36)

                    Button(action: {
                        // TODO: Update event
                        Analytics.shared.introClick(.next, page: .start)
                        onFinish()
                    }) {
                        Text(verbatim: .localized(.getStarted))
                            .font(.body)
                            .foregroundColor(theme.buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(theme.buttonBackgroundColor)
                            .cornerRadius(24)
                    }
                }
                // TODO: Max 479 width for content on iPad
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 112 : 16)
                .padding(.bottom, 16)
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 544 : .infinity)
                .opacity(bodyOpacity)
            }
        }
        .onAppear {
            // TODO: Update event
            Analytics.shared.introDisplaying(page: .start)

            startAnimationSequence()
        }
        .ecosiaThemed(windowUUID, $theme)
    }

    private func startAnimationSequence() {
        let screenWidth = UIScreen.main.bounds.width - 32

        // Phase 1: Show centered rounded square mask with logo (500ms delay, 500ms duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showRoundedBackground = true
            transitionMaskWidth = screenWidth
            withAnimation(.easeInOut(duration: 0.5)) {
                transitionMaskScale = 1.0
            }
        }

        // Phase 2: Animate in welcome text, move logo down (350ms duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.35)) {
                welcomeTextOpacity = 1.0
                welcomeTextOffset = -23.0
                logoOffset = 14.0
                animationPhase = .phase1Complete
            }
        }

        // Phase 3: Grow window to full screen, move logo to final position, show body (500ms delay, 350ms duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            withAnimation(.easeInOut(duration: 0.35)) {
                transitionMaskScale = 1.0 // Already at full scale from phase 1
                transitionMaskHeight = UIScreen.main.bounds.height
                transitionMaskWidth = UIScreen.main.bounds.width
                logoOffset = -282.0
                welcomeTextOffset = -305.0
                bodyOpacity = 1.0
                backgroundOpacity = 0.0
                animationPhase = .phase3Complete
            }
        }
    }

    private var simplestWayString: String {
        .localized(.theSimplestWay)
    }
}

extension WelcomeView.AnimationPhase {
    var isPhase3: Bool {
        self == .phase3Complete
    }
}

// MARK: - WelcomeViewTheme

struct WelcomeViewTheme: EcosiaThemeable {
    var contentTextColor = Color.white
    var buttonTextColor = Color.white
    var buttonBackgroundColor = Color.green

    mutating func applyTheme(theme: Theme) {
        contentTextColor = Color(theme.colors.ecosia.textStaticLight)
        buttonTextColor = Color(theme.colors.ecosia.buttonContentSecondaryStatic)
        buttonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundFeatured)
    }
}

// MARK: - Looping Video Player

class VideoPlayerView: UIView {
    let playerLayer = AVPlayerLayer()

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let playerLayer = layer as? AVPlayerLayer {
            playerLayer.videoGravity = .resizeAspectFill
        }
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String

    func makeUIView(context: Context) -> UIView {
        let view = VideoPlayerView()

        guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: "mov") else {
            // Fallback to static image if video not found
            let imageView = UIImageView(image: UIImage(named: "forest"))
            imageView.contentMode = .scaleAspectFill
            imageView.frame = view.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(imageView)
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

        // Monitor player status
        let statusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { status in
                switch status {
                case .readyToPlay:
                    player.play()
                case .failed:
                    break
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }

        context.coordinator.statusObserver = statusObserver

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
