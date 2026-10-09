// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

@MainActor
final class EcosiaStartAtHomeMiddleware {
    private let windowManager: WindowManager
    private let logger: Logger
    private let dateProvider: DateProvider

    // Ecosia: profile and prefs are not used in our overridden startAtHomeProvider (which always
    // returns shouldStartAtHome: false). Removing them avoids crashes when AppContainer is reset
    // during unit-test setUp before this middleware is constructed (e.g. from StoreTestUtility).
    init(windowManager: WindowManager = (AppContainer.shared.resolveOptional() as WindowManager?) ?? WindowManagerImplementation(),
         logger: Logger = DefaultLogger.shared,
         dateProvider: DateProvider = SystemDateProvider()) {
        self.windowManager = windowManager
        self.logger = logger
        self.dateProvider = dateProvider
    }

    lazy var startAtHomeProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case StartAtHomeActionType.didBrowserBecomeActive:
            store.dispatch(
                StartAtHomeAction(
                    shouldStartAtHome: false,
                    windowUUID: action.windowUUID,
                    actionType: StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted
                )
            )
        default: break
        }
    }
}
