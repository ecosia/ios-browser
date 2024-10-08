// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct SeedCounterView: View {
    
    // MARK: - Properties
    
    private let progressManagerType: SeedProgressManagerProtocol.Type
    private let twinkleDuration = 10.0
    @State private var seedsCollected: Int = 0
    @State private var level: Int = 1
    @State private var progressValue: CGFloat = 0.0
    @State private var showTwinkle = false
    @StateObject var theme = ArcTheme()
    @Environment(\.themeType) var themeVal
    
    // MARK: - Init
    
    init(progressManagerType: SeedProgressManagerProtocol.Type) {
        self.progressManagerType = progressManagerType
        _seedsCollected = State(initialValue: progressManagerType.loadTotalSeedsCollected())
        _level = State(initialValue: progressManagerType.loadCurrentLevel())
        _progressValue = State(initialValue: progressManagerType.calculateInnerProgress())
    }
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                SeedProgressView(progressValue: progressValue,
                                 theme: theme)
                
                Text("\(Int(seedsCollected))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .zIndex(0)
            
            if showTwinkle {
                TwinkleView(active: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped(antialiased: false)
                    .allowsHitTesting(false)
                    .zIndex(1)
                    .onAppear {
                        // Automatically stop showing twinkle after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + twinkleDuration) {
                            showTwinkle = false
                        }
                    }
            }
        }
        .onAppear {
            // Add observer for progress updates
            NotificationCenter.default.addObserver(forName: progressManagerType.progressUpdatedNotification, object: nil, queue: .main) { _ in
                // Update the state when progress changes
                self.seedsCollected = progressManagerType.loadTotalSeedsCollected()
                self.level = progressManagerType.loadCurrentLevel()
                self.progressValue = progressManagerType.calculateInnerProgress()
            }
            NotificationCenter.default.addObserver(forName: UserDefaultsSeedProgressManager.levelUpNotification, object: nil, queue: .main) { _ in
                // Trigger the twinkle animation when level up occurs
                showTwinkle = true
            }
            applyTheme(theme: themeVal.theme)
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: progressManagerType.progressUpdatedNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UserDefaultsSeedProgressManager.levelUpNotification, object: nil)
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
}
