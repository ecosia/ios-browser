// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct SeedCounterView: View {
    
    // MARK: - Properties
    
    private let progressManagerType: SeedProgressManagerProtocol.Type
    @State private var seedsCollected: Int = 0
    @State private var level: Int = 1
    @State private var progressValue: CGFloat = 0.0
    @State private var showZoomCircle = false
    @StateObject var theme = ArcTheme()
    @Environment(\.themeType) var themeVal
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Init
    
    init(progressManagerType: SeedProgressManagerProtocol.Type) {
        self.progressManagerType = progressManagerType
        _seedsCollected = State(initialValue: progressManagerType.loadTotalSeedsCollected())
        _level = State(initialValue: progressManagerType.loadCurrentLevel())
        _progressValue = State(initialValue: progressManagerType.calculateInnerProgress())
    }
    
    // MARK: - View
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                SeedProgressView(progressValue: progressValue,
                                 theme: theme)
                
                Text("\(Int(seedsCollected))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .scaledToFill()
                    .modifier(TextAnimationModifier(seedsCollected: seedsCollected))
            }
            if showZoomCircle {
                NewSeedCollectedCircleView(seedsCollected: seedsCollected)
                    .offset(x: 20, y: -20)
                    .transition(.scale(scale: 0.1, anchor: .center))
                    .scaleEffect(showZoomCircle ? 1.0 : 0.1)
                    .animation(reduceMotion ? .none : .linear(duration: 10), value: showZoomCircle)
            }
        }
        .onAppear {
            // Add observer for progress updates
            NotificationCenter.default.addObserver(forName: progressManagerType.progressUpdatedNotification, object: nil, queue: .main) { _ in
                // Update the state when progress changes
                self.triggerUpdateValues()
                self.showZoomEffect()
            }
            applyTheme(theme: themeVal.theme)
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: progressManagerType.progressUpdatedNotification, object: nil)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }
    
    // MARK: - Helpers
    
    func applyTheme(theme: Theme) {
        self.theme.backgroundColor = Color(.legacyTheme.ecosia.primaryBackground)
        self.theme.progressColor = Color(.legacyTheme.ecosia.primaryButtonActive)
    }
    
    private func showZoomEffect() {
        if reduceMotion {
            // No animation, just appear and disappear
            showZoomCircle = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showZoomCircle = false
            }
        } else {
            // Animate the zoom effect
            withAnimation(.linear(duration: 0.5)) {
                showZoomCircle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.linear(duration: 0.5)) {
                    self.showZoomCircle = false
                }
            }
        }
    }
    
    private func triggerUpdateValues() {
        if BrowserKitInformation.shared.buildChannel == .release {
            updateValues()
        } else {
            // In ANY other build (e.g. adhoc, development), delay updateValues by 5 seconds
            // so they can be seen and perhaps QAd as well
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.updateValues()
            }
        }
    }
    
    private func updateValues() {
        self.seedsCollected = progressManagerType.loadTotalSeedsCollected()
        self.level = progressManagerType.loadCurrentLevel()
        self.progressValue = progressManagerType.calculateInnerProgress()
    }
}

struct NewSeedCollectedCircleView: View {
    var seedsCollected: Int
    
    var body: some View {
        Circle()
            .fill(Color(.legacyTheme.ecosia.peach))
            .frame(width: 20, height: 20)
            .overlay(
                Text("\(seedsCollected)")
                    .font(.caption)
                    .foregroundColor(.white)
            )
    }
}

struct TextAnimationModifier: ViewModifier {
    var seedsCollected: Int

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            if UIAccessibility.isReduceMotionEnabled {
                content
            } else {
                content
                    .contentTransition(.numericText(value: Double(seedsCollected)))
                    .animation(.default, value: seedsCollected)
            }
        } else {
            content
                .animation(!UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.5) : .none, value: seedsCollected)
        }
    }
}
