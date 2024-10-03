// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

final class SeedTheme: ObservableObject {
    @Published var backgroundColor: Color = .clear
    @Published var progressColor: Color = .clear
}

struct SeedCounterView: View {

    // MARK: - Properties
    
    @State private var seedsCollected: Int = SeedProgressManager.loadSeedsCollected()
    @State private var level: Int = SeedProgressManager.loadLevel()
    @State private var progressValue: CGFloat = SeedProgressManager.calculateProgress()
    @StateObject var theme = SeedTheme()
    @Environment(\.themeType)
    var themeVal

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            SeedProgressView(progressValue: progressValue,
                             theme: theme)
                
            Text("\(Int(seedsCollected))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
        }
        .onAppear {
            // Add observer for progress updates
            NotificationCenter.default.addObserver(forName: SeedProgressManager.progressUpdatedNotification, object: nil, queue: .main) { _ in
                // Update the state when progress changes
                self.seedsCollected = SeedProgressManager.loadSeedsCollected()
                self.level = SeedProgressManager.loadLevel()
                self.progressValue = SeedProgressManager.calculateProgress()
            }
            applyTheme(theme: themeVal.theme)
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: SeedProgressManager.progressUpdatedNotification, object: nil)
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
