// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import Common

protocol InactiveTabsCFRProtocol: AnyObject {
    func setupCFR(with view: UILabel)
    func presentCFR()
    func presentUndoToast(tabsCount: Int, completion: @escaping (Bool) -> Void)
    func presentUndoSingleToast(completion: @escaping (Bool) -> Void)
}

class LegacyInactiveTabViewModel {
    private var inactiveTabModel = LegacyInactiveTabModel()
    private var allTabs = [Tab]()
    private var selectedTab: Tab?
    var inactiveTabs = [Tab]()
    var activeTabs = [Tab]()
    var shouldHideInactiveTabs = false
    var theme: Theme

    private var appSessionManager: AppSessionProvider

    var isActiveTabsEmpty: Bool {
        return activeTabs.isEmpty || shouldHideInactiveTabs
    }

    init(theme: Theme,
         appSessionManager: AppSessionProvider = AppContainer.shared.resolve()) {
        self.theme = theme
        self.appSessionManager = appSessionManager
    }

    func updateInactiveTabs(with selectedTab: Tab?, tabs: [Tab]) {
        self.allTabs = tabs
        self.selectedTab = selectedTab
        clearAll()

        inactiveTabModel.tabWithStatus = LegacyInactiveTabModel.get()?.tabWithStatus ?? [String: InactiveTabStates]()

        updateModelState(state: appSessionManager.tabUpdateState)
        appSessionManager.tabUpdateState = .sameSession

        updateFilteredTabs()
    }

    // MARK: - Private functions
    private func updateModelState(state: TabUpdateState) {
        let hasRunInactiveTabFeatureBefore = LegacyInactiveTabModel.hasRunInactiveTabFeatureBefore
        if hasRunInactiveTabFeatureBefore == false { LegacyInactiveTabModel.hasRunInactiveTabFeatureBefore = true }

        for tab in self.allTabs {
            // 1. Initializing and assigning an empty inactive tab state to the inactiveTabModel mode
            if inactiveTabModel.tabWithStatus[tab.tabUUID] == nil {
                inactiveTabModel.tabWithStatus[tab.tabUUID] = InactiveTabStates()
            }

            // 2. Current tab type from inactive tab model
            // Note:
            //  a) newly assigned inactive tab model will have empty `tabWithStatus`
            //     with nil current and next states
            //  b) an older inactive tab model will have a proper `tabWithStatus`
            let tabType = inactiveTabModel.tabWithStatus[tab.tabUUID]

            // 3. All tabs should start with a normal current state if they don't have any current state
            if tabType?.currentState == nil { inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal }

            if tab == selectedTab {
                inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal
            } else if tabType?.nextState == .shouldBecomeInactive && state == .sameSession {
                continue
            } else if tab == selectedTab || tab.isActive {
                inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .normal
            } else if tab.isInactive {
                if hasRunInactiveTabFeatureBefore == false {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = .shouldBecomeInactive
                } else if state == .coldStart {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.currentState = .inactive
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = nil
                } else if state == .sameSession && tabType?.currentState != .inactive {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.nextState = .shouldBecomeInactive
                }
            }
        }

        LegacyInactiveTabModel.save(tabModel: inactiveTabModel)
    }

    private func updateFilteredTabs() {
        inactiveTabModel.tabWithStatus = LegacyInactiveTabModel.get()?.tabWithStatus ?? [String: InactiveTabStates]()
        clearAll()
        for tab in self.allTabs {
            // Ecosia: Skip invisible tabs (authentication tabs)
            guard !tab.isInvisible else { continue }
            
            let status = inactiveTabModel.tabWithStatus[tab.tabUUID]
            if status == nil {
                activeTabs.append(tab)
            } else if let status = status, let currentState = status.currentState {
                addTab(state: currentState, tab: tab)
            }
        }
    }

    private func addTab(state: InactiveTabStatus?, tab: Tab) {
        // Ecosia: Skip invisible tabs (authentication tabs)
        guard !tab.isInvisible else { return }
        
        switch state {
        case .inactive:
            inactiveTabs.append(tab)
        case .normal, .none:
            activeTabs.append(tab)
        case .shouldBecomeInactive: break
        }
    }

    private func clearAll() {
        activeTabs.removeAll()
        inactiveTabs.removeAll()
    }
}
