// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

final class SeedProgress: ObservableObject {
    @Published var value: CGFloat = 0
}

final class SeedTheme: ObservableObject {
    @Published var backgroundColor: Color = .clear
    @Published var progressColor: Color = .clear
}

struct SeedCounterView: View {

    // MARK: - Properties
    
    @StateObject var progress = SeedProgress()
    @StateObject var theme = SeedTheme()
    @Environment(\.themeType)
    var themeVal

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            SeedProgressView(progress: progress,
                             theme: theme)
            
            Text("\(Int(progress.value))")
                .font(.subheadline)
                .fontWeight(.semibold)
        }.onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
        
        .onChange(of: progress.value) { newProgress in
            if newProgress >= 1.0 {
                progress.value += 1
            }
        }
}
    
    
    
    // MARK: - Helpers
     
    func increaseProgress(by amount: CGFloat) {
        let newProgress = progress.value + amount
        progress.value = min(newProgress, 1.0) // Update between 0 and 1
    }
    
    func applyTheme(theme: Theme) {
        self.theme.backgroundColor = Color(.legacyTheme.ecosia.primaryBackground)
        self.theme.progressColor = Color(.legacyTheme.ecosia.primaryButtonActive)
    }    
}
