// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Ecosia

/// Hosts NTP omnibox sheets using the same SwiftUI `.sheet` presentation as `EcosiaAccountImpactView`.
@available(iOS 16.0, *)
struct NTPOmniboxSheetPresenter: View {
    @ObservedObject var sheetState: NTPOmniboxSheetState
    @ObservedObject private var authStateProvider = EcosiaAuthUIStateProvider.shared
    let windowUUID: WindowUUID

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .sheet(isPresented: $sheetState.showSignInSheet, onDismiss: {
                sheetState.handleSignInSheetDismissed()
            }) {
                OmniboxUploadSignInSheet(
                    windowUUID: windowUUID,
                    onSignIn: {
                        sheetState.handleSignInSheetSignInTapped()
                    },
                    onCreateAccount: {
                        sheetState.handleSignInSheetCreateAccountTapped()
                    },
                    onDismiss: {
                        sheetState.showSignInSheet = false
                    }
                )
            }
            .sheet(isPresented: $sheetState.showUploadDrawer, onDismiss: {
                sheetState.handleUploadDrawerDismissed()
            }) {
                OmniboxUploadDrawerSheet(windowUUID: windowUUID) { option in
                    sheetState.handleUploadOptionSelected(option)
                }
            }
            .onChange(of: authStateProvider.isLoggedIn) { isLoggedIn in
                if isLoggedIn {
                    sheetState.handleAuthenticationSucceeded()
                }
            }
    }
}
