// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
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
        static let maskInitialWidthMargin: CGFloat = 8
        static let maskCornerRadius: CGFloat = 16
        static let contentMaxWidthIPad: CGFloat = 479
        static let contentPadding: CGFloat = 16
        static let bodyTitleBottomSpacing: CGFloat = 20
        static let bodySubtitleBottomSpacing: CGFloat = 36
        static let buttonHeight: CGFloat = 48
        static let buttonCornerRadius: CGFloat = 24
        static let exitOffset: CGFloat = 50

        // Gradient dimensions
        static let centeredGradientSize: CGFloat = 210
        static let topGradientBottomOffset: CGFloat = 19
        static let bodyGradientTopOffset: CGFloat = 20
        static let bodyGradientBottomOffset: CGFloat = 24

        // Animation timings (relative delays between phases)
        static let initialDelay: TimeInterval = 0.5
        static let phase1Duration: TimeInterval = 0.5
        static let gradientFadeDuration: TimeInterval = 0.2
        static let phase2Delay: TimeInterval = 0.15
        static let phase2Duration: TimeInterval = 0.35
        static let phase3Delay: TimeInterval = 0.5
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
    @State private var showVideoBackground: Bool = false
    @State private var backgroundOpacity: Double = 1.0
    @State private var centeredGradientOpacity: Double = 0.0
    @State private var topGradientOpacity: Double = 0.0
    @State private var bodyGradientOpacity: Double = 0.0
    @State private var theme = WelcomeViewTheme()
    @State private var isVideoReady = false
    @State private var animationTask: Task<Void, Never>?
    @State private var hasAppeared = false

    private let reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled

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
            ZStack {
                LoopingVideoPlayer(videoName: "welcome_background") {
                    isVideoReady = true
                }

                // Centered radial gradient behind logo
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.55),
                        Color.black.opacity(0)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: UX.centeredGradientSize / 2
                )
                .opacity(centeredGradientOpacity)
            }
            .mask(
                RoundedRectangle(cornerRadius: UX.maskCornerRadius)
                    .frame(height: transitionMaskHeight)
                    .frame(maxWidth: transitionMaskWidth)
                    .scaleEffect(transitionMaskScale, anchor: .center)
            )
            .ignoresSafeArea(edges: .all)
            .opacity(showVideoBackground ? 1 : 0)

            // Top vertical gradient behind logo
            if animationPhase == .phase3Complete {
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.38),
                            Color.black.opacity(0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: topGradientHeight)

                    Spacer()
                }
                .ignoresSafeArea()
                .opacity(topGradientOpacity)
            }

            // Welcome text
            Text(verbatim: .localized(.welcomeTo))
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

                    VStack(spacing: UX.bodyTitleBottomSpacing) {
                        Text(verbatim: .localized(.realChangeAtYourFingertips))
                            .font(.ecosiaFamilyBrand(size: .ecosia.font._6l))
                            .foregroundStyle(theme.contentTextColor)
                            .multilineTextAlignment(.center)

                        Text(verbatim: .localized(.joinMillionsPeople))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.contentTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, UX.bodyGradientTopOffset)
                    .padding(.bottom, UX.bodySubtitleBottomSpacing)
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0), location: 0.0),
                                .init(color: Color.black.opacity(0.35), location: 0.3),
                                .init(color: Color.black.opacity(0.24), location: 0.6),
                                .init(color: Color.black.opacity(0), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(width: screenWidth)
                        .opacity(bodyGradientOpacity)
                    )

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
                .padding(.horizontal, UX.contentPadding)
                .padding(.top, UX.contentPadding)
                .padding(.bottom, UX.contentPadding + safeAreaBottom)
                .frame(maxWidth: contentMaxWidth)
                .opacity(bodyOpacity)
                .offset(y: bodyOffset)
            }
        }
        // Needed so initial state matches launch screen
        .ignoresSafeArea()
        // Theme has to be applied before onAppear for logo color
        .ecosiaThemed(windowUUID, $theme)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            Analytics.shared.introWelcome(action: .display)

            logoColor = theme.brandPrimaryColor

            if reduceMotionEnabled {
                skipToFinalState()
            } else {
                // Animation will start when video is ready
            }
        }
        .onChange(of: isVideoReady) { ready in
            if ready && !reduceMotionEnabled && hasAppeared {
                startAnimationSequence()
            }
        }
    }

    private func skipToFinalState() {
        // For reduced motion: skip animations and go directly to final state
        showVideoBackground = true
        transitionMaskScale = 1.0
        transitionMaskHeight = screenHeight
        transitionMaskWidth = screenWidth
        logoColor = theme.contentTextColor
        welcomeTextOpacity = 1.0
        logoOpacity = 1.0
        logoOffset = phase3LogoOffset
        welcomeTextOffset = phase3WelcomeTextOffset
        bodyOpacity = 1.0
        topGradientOpacity = 1.0
        bodyGradientOpacity = 1.0
        centeredGradientOpacity = 0.0
        backgroundOpacity = 0.0
        animationPhase = .phase3Complete
    }

    private func startAnimationSequence() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            // Phase 1: Show centered rounded square mask with logo
            try? await Task.sleep(duration: UX.initialDelay)
            guard !Task.isCancelled else { return }

            showVideoBackground = true
            transitionMaskWidth = screenWidth - UX.maskInitialWidthMargin * 2

            await animate(duration: UX.phase1Duration) {
                transitionMaskScale = 1.0
                logoColor = theme.contentTextColor
            }

            guard !Task.isCancelled else { return }

            // Fade in centered gradient directly after phase 1 ends
            await animate(duration: UX.gradientFadeDuration) {
                centeredGradientOpacity = 1.0
            }

            guard !Task.isCancelled else { return }

            // Phase 2: Animate in welcome text above, move logo down
            try? await Task.sleep(duration: UX.phase2Delay)
            guard !Task.isCancelled else { return }

            await animate(duration: UX.phase2Duration) {
                welcomeTextOpacity = 1.0
                welcomeTextOffset = phase2WelcomeTextOffset
                logoOffset = phase2LogoOffset
                animationPhase = .phase1Complete
            }

            guard !Task.isCancelled else { return }

            // Phase 3: Grow window to full screen, move both to final position, show body
            try? await Task.sleep(duration: UX.phase3Delay)
            guard !Task.isCancelled else { return }

            await animate(duration: UX.phase3Duration) {
                transitionMaskScale = 1.0 // Already at full scale from phase 1
                transitionMaskHeight = screenHeight
                transitionMaskWidth = screenWidth
                logoOffset = phase3LogoOffset
                welcomeTextOffset = phase3WelcomeTextOffset
                bodyOpacity = 1.0
                topGradientOpacity = 1.0
                bodyGradientOpacity = 1.0
                centeredGradientOpacity = 0.0
                backgroundOpacity = 0.0
                animationPhase = .phase3Complete
            }
        }
    }

    @MainActor
    private func animate(duration: TimeInterval, _ updates: @escaping () -> Void) async {
        withAnimation(.easeInOut(duration: duration)) {
            updates()
        }
        try? await Task.sleep(duration: duration)
    }

    private func startExitAnimation() {
        animationTask?.cancel()

        // Phase 4: Exit transition - move content out while fading
        animationTask = Task { @MainActor in
            await animate(duration: UX.exitDuration) {
                logoOffset = exitLogoOffset
                welcomeTextOffset = exitWelcomeTextOffset
                logoOpacity = 0.0
                bodyOffset = UX.exitOffset
                bodyOpacity = 0.0
                welcomeTextOpacity = 0.0
                backgroundOpacity = 1.0
                animationPhase = .final
            }

            guard !Task.isCancelled else { return }
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

    private var safeAreaBottom: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
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

    // Top gradient extends from top of screen to some points below logo
    private var topGradientHeight: CGFloat {
        let logoBottomY = screenHeight / 2 + phase3LogoOffset + (UX.logoHeight / 2)
        return logoBottomY + UX.topGradientBottomOffset
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
