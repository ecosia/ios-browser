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
    
    @StateObject var progressManager = SeedProgressManager()
    @StateObject var theme = SeedTheme()
    @Environment(\.themeType)
    var themeVal

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            SeedProgressView(progressValue: progressManager.progressValue,
                             theme: theme)
                
            Text("\(Int(progressManager.seedsCollected))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
        }
        .onAppear {
            progressManager.updateProgress()
            applyTheme(theme: themeVal.theme)
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
