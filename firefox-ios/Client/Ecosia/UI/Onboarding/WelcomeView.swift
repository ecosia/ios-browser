// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import AVKit
import Combine
import Common
import Ecosia

struct WelcomeView: View {

    // MARK: - UX Constants
    private struct UX {
        static let logoWidth: CGFloat = 112
        static let logoHeight: CGFloat = 28
        static let logoContainerSpacing: CGFloat = 12
        static let welcomeTextFontSize: CGFloat = 17
        static let logoTopOffsetIPhone: CGFloat = 46
        static let logoTopOffsetIPad: CGFloat = 66
        static let maskInitialHeight: CGFloat = 384
        static let maskInitialWidthMargin: CGFloat = 384
        static let maskCornerRadius: CGFloat = 16
        static let contentMaxWidthIPad: CGFloat = 479
        static let contentPadding: CGFloat = 16
        static let bodyTitleBottomSpacing: CGFloat = 20
        static let bodySubtitleBottomSpacing: CGFloat = 36
        static let buttonHeight: CGFloat = 48
        static let buttonCornerRadius: CGFloat = 24
        static let exitOffset: CGFloat = 50

        // Animation timings
        static let phase1Delay: TimeInterval = 0.5
        static let phase1Duration: TimeInterval = 0.5
        static let phase2Delay: TimeInterval = 1.0
        static let phase2Duration: TimeInterval = 0.35
        static let phase3Delay: TimeInterval = 1.85
        static let phase3Duration: TimeInterval = 0.35
        static let exitDuration: TimeInterval = 0.35
    }

    // MARK: - State

    @State private var animationPhase: AnimationPhase = .initial
    @State private var transitionMaskScale: CGFloat = 0.0
    @State private var transitionMaskHeight: CGFloat = UX.maskInitialHeight
    @State private var transitionMaskWidth: CGFloat = 0.0
    @State private var welcomeTextOpacity: Double = 0.0
    @State private var logoOpacity: Double = 1.0
    @State private var logoColor = Color(uiColor: UIColor.systemBackground) // Will be brandPrimary
    @State private var logoOffset: CGFloat = 0.0
    @State private var welcomeTextOffset: CGFloat = 0.0
    @State private var bodyOpacity: Double = 0.0
    @State private var bodyOffset: CGFloat = 0.0
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
        case final
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
                    .mask(
                        RoundedRectangle(cornerRadius: UX.maskCornerRadius)
                            .frame(height: transitionMaskHeight)
                            .frame(maxWidth: transitionMaskWidth)
                            .scaleEffect(transitionMaskScale, anchor: .center)
                    )
                    .ignoresSafeArea(edges: .all)
            }

            // TODO: Add black gradient behind logo and body for readibility

            // Welcome text
            Text("Welcome to")
                .font(.system(size: UX.welcomeTextFontSize, weight: .semibold))
                .foregroundColor(theme.contentTextColor)
                .multilineTextAlignment(.center)
                .opacity(welcomeTextOpacity)
                .offset(y: welcomeTextOffset)
                .frame(maxWidth: transitionMaskWidth)

            // Logo
            Image("ecosiaLogoLaunch")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(logoColor)
                .frame(width: UX.logoWidth, height: UX.logoHeight)
                .opacity(logoOpacity)
                .offset(y: logoOffset)
                .frame(maxWidth: transitionMaskWidth)
                .accessibilityLabel(String.localized(.ecosiaLogoAccessibilityLabel))
                .accessibilityIdentifier(AccessibilityIdentifiers.Ecosia.logo)

            // Content
            if animationPhase == .phase3Complete {
                VStack {
                    Spacer()

                    Text("Real change at your fingertips")
                        .font(.ecosiaFamilyBrand(size: .ecosia.font._6l))
                        .foregroundStyle(theme.contentTextColor)
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: UX.bodyTitleBottomSpacing)

                    Text("Join 20 million people making a difference every day")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.contentTextColor)
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: UX.bodySubtitleBottomSpacing)

                    Button(action: {
                        Analytics.shared.introWelcome(action: .click)
                        startExitAnimation()
                    }) {
                        Text(verbatim: .localized(.getStarted))
                            .font(.body)
                            .foregroundColor(theme.buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: UX.buttonHeight)
                            .background(theme.buttonBackgroundColor)
                            .cornerRadius(UX.buttonCornerRadius)
                    }
                }
                .padding(.all, UX.contentPadding)
                .frame(maxWidth: contentMaxWidth)
                .opacity(bodyOpacity)
                .offset(y: bodyOffset)
            }
        }
        // Theme has to be applied before onAppear for logo color
        .ecosiaThemed(windowUUID, $theme)
        .onAppear {
            Analytics.shared.introWelcome(action: .display)

            logoColor = theme.brandPrimaryColor
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        // Phase 1: Show centered rounded square mask with logo
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.phase1Delay) {
            showRoundedBackground = true
            transitionMaskWidth = UX.maskInitialWidthMargin * 2
            withAnimation(.easeInOut(duration: UX.phase1Duration)) {
                transitionMaskScale = 1.0
                logoColor = theme.contentTextColor
            }
        }

        // Phase 2: Animate in welcome text above, move logo down
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.phase2Delay) {
            withAnimation(.easeInOut(duration: UX.phase2Duration)) {
                welcomeTextOpacity = 1.0
                welcomeTextOffset = phase2WelcomeTextOffset
                logoOffset = phase2LogoOffset
                animationPhase = .phase1Complete
            }
        }

        // Phase 3: Grow window to full screen, move both to final position, show body
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.phase3Delay) {
            withAnimation(.easeInOut(duration: UX.phase3Duration)) {
                transitionMaskScale = 1.0 // Already at full scale from phase 1
                transitionMaskHeight = screenHeight
                transitionMaskWidth = screenWidth
                logoOffset = phase3LogoOffset
                welcomeTextOffset = phase3WelcomeTextOffset
                bodyOpacity = 1.0
                backgroundOpacity = 0.0
                animationPhase = .phase3Complete
            }
        }
    }

    private func startExitAnimation() {
        // Phase 4: Exit transition - move content out while fading
        withAnimation(.easeInOut(duration: UX.exitDuration)) {
            logoOffset = exitLogoOffset
            welcomeTextOffset = exitWelcomeTextOffset
            logoOpacity = 0.0
            bodyOffset = UX.exitOffset
            bodyOpacity = 0.0
            welcomeTextOpacity = 0.0
            backgroundOpacity = 1.0
            animationPhase = .final
        }

        // Dismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.exitDuration) {
            onFinish()
        }
    }

    private var simplestWayString: String {
        .localized(.theSimplestWay)
    }
}

// MARK: - Dynamic Layout Calculations

extension WelcomeView {

    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var logoTopOffset: CGFloat {
        isIPad ? UX.logoTopOffsetIPad : UX.logoTopOffsetIPhone
    }

    private var welcomeTextHeight: CGFloat {
        let font = UIFont.systemFont(ofSize: UX.welcomeTextFontSize, weight: .semibold)
        return font.lineHeight
    }

    private var logoContainerHeight: CGFloat {
        welcomeTextHeight + UX.logoContainerSpacing + UX.logoHeight
    }

    private var safeAreaTop: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }

    // Logo moves down to make room for welcome text
    private var phase2LogoOffset: CGFloat {
        (welcomeTextHeight + UX.logoContainerSpacing) / 2
    }

    // Welcome text appears above the logo, maintaining spacing
    private var phase2WelcomeTextOffset: CGFloat {
        phase2LogoOffset - (UX.logoHeight / 2) - UX.logoContainerSpacing - (welcomeTextHeight / 2)
    }

    // Position welcome text at specified offset from top
    private var phase3WelcomeTextOffset: CGFloat {
        let distanceFromTop = safeAreaTop + logoTopOffset + (welcomeTextHeight / 2)
        return distanceFromTop - (screenHeight / 2)
    }

    // Logo positioned below welcome text
    private var phase3LogoOffset: CGFloat {
        phase3WelcomeTextOffset + (welcomeTextHeight / 2) + UX.logoContainerSpacing + (UX.logoHeight / 2)
    }

    // Move further up by the exit offset
    private var exitLogoOffset: CGFloat {
        phase3LogoOffset - UX.exitOffset
    }

    private var exitWelcomeTextOffset: CGFloat {
        phase3WelcomeTextOffset - UX.exitOffset
    }

    private var contentMaxWidth: CGFloat {
        isIPad ? UX.contentMaxWidthIPad : .infinity
    }
}

// MARK: - WelcomeViewTheme

struct WelcomeViewTheme: EcosiaThemeable {
    var contentTextColor = Color.white
    var buttonTextColor = Color.white
    var buttonBackgroundColor = Color.green
    var brandPrimaryColor = Color.green

    mutating func applyTheme(theme: Theme) {
        contentTextColor = Color(theme.colors.ecosia.textStaticLight)
        buttonTextColor = Color(theme.colors.ecosia.buttonContentSecondaryStatic)
        buttonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundFeatured)
        brandPrimaryColor = Color(theme.colors.ecosia.brandPrimary)
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
            playerLayer.frame = bounds
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
