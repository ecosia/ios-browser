// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct SeedProgressView: View {
    
    // MARK: - UX Constants
    
    private enum UX {
        static let seedLineWidth: CGFloat = 3
        static let seedIconWidthHeight: CGFloat = 24
        static let seedIconBottomOffset: CGFloat = 8
    }

    // MARK: - Properties
    
    var progress: SeedProgressEntity
    @ObservedObject var theme: SeedTheme
    
    // MARK: - View
    
    var body: some View {
        ZStack(alignment: .top) {
            ArchProgressView(progress: calculateProgress(),
                             lineWidth: UX.seedLineWidth,
                             theme: theme
            )
            .offset(y: -UX.seedLineWidth * 2)
            
            Image("seedIcon")
                .resizable()
                .frame(width: UX.seedIconWidthHeight, height: UX.seedIconWidthHeight)
                .offset(y: UX.seedIconBottomOffset)
        }
    }
}

extension SeedProgressView {
    
    func calculateProgress() -> CGFloat {
        if progress.level == 1 {
            return CGFloat(progress.seedsCollected) / 5.0
        } else if progress.level == 2 {
            return CGFloat(progress.seedsCollected) / 7.0
        } else {
            return 1.0 // Full progress after level 2
        }
    }
}
