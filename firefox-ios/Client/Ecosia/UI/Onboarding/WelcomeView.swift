// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import AVKit
import Common
import Ecosia

struct WelcomeView: View {
    @State private var showContent = false
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    
    let windowUUID: WindowUUID
    let onFinish: () -> Void
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoPlayer(videoName: "welcome_background")
                .ignoresSafeArea()
            
            // Logo
            VStack {
                if showContent {
                    Image("ecosiaLogoLaunch")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 48)
                        .foregroundColor(.white)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Ecosia.logo)
                        .padding(.top, 24)
                    
                    Spacer()
                } else {
                    Spacer()
                    
                    Image("ecosiaLogoLaunch")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 72)
                        .foregroundColor(.white)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    Spacer()
                }
            }
            
            // Content
            if showContent {
                VStack(spacing: 10) {
                    Spacer()
                    
                    IntroTextView(text: simplestWayString)
                        .accessibilityLabel(simplestWayString.replacingOccurrences(of: "\n", with: ""))
                    
                    Spacer()
                        .frame(height: 20)
                    
                    Button(action: {
                        // TODO: Update event
                        Analytics.shared.introClick(.next, page: .start)
                        onFinish()
                    }) {
                        Text(verbatim: .localized(.getStarted))
                            .font(.callout)
                            .foregroundColor(Color(EcosiaLightTheme().colors.ecosia.textPrimary))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(EcosiaLightTheme().colors.ecosia.buttonBackgroundSecondary))
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 112 : 16)
                .padding(.bottom, 16)
                .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 544 : .infinity)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // TODO: Update event
            Analytics.shared.introDisplaying(page: .start)
            
            // Animate content appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    logoScale = 0.8
                    logoOpacity = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showContent = true
                }
            }
        }
    }
    
    private var simplestWayString: String {
        .localized(.theSimplestWay)
    }
}

// MARK: - Intro Text View with Inline Images

struct IntroTextView: View {
    let text: String
    
    var body: some View {
        let splits = text.components(separatedBy: .newlines)
        
        if splits.count == 3 {
            Text(splits[0])
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            + Text(" ")
            + Text(Image("splashTree1"))
                .baselineOffset(-2)
            + Text(splits[1])
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            + Text(" ")
            + Text(Image("splashTree2"))
                .baselineOffset(-2)
            + Text(splits[2])
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        } else {
            Text(text)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
    }
}

// MARK: - Looping Video Player

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // TODO: Add video file
        guard let videoURL = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            // Fallback to static image if video not found
            let imageView = UIImageView(image: UIImage(named: "forest"))
            imageView.contentMode = .scaleAspectFill
            imageView.frame = view.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(imageView)
            return view
        }
        
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        player.play()
        
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerLayer = context.coordinator.playerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        
        deinit {
            player?.pause()
            NotificationCenter.default.removeObserver(self)
        }
    }
}
