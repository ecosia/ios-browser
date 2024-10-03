// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct SeedCounterView: View {
    @State private var progress: CGFloat = 0.0
    @State private var seedCount: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            SeedProgressView(progress: $progress)
            
            Text("\(seedCount)")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .onChange(of: progress) { newProgress in
            // When progress reaches 1, increment the seed count and reset progress
            if newProgress >= 1.0 {
                seedCount += 1
                progress = 0.0 // Reset progress after completion
            }
        }
    }

    // Method to increase the progress
    func increaseProgress(by amount: CGFloat) {
        let newProgress = progress + amount
        progress = min(newProgress, 1.0) // Update between 0 and 1
    }
}
