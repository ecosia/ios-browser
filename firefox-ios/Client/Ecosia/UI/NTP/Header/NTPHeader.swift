// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

protocol NTPHeaderDelegate: AnyObject {
    func headerOpenAISearch()
}

/// NTP header cell containing multiple Ecosia-specific actions like AI search
@available(iOS 16.0, *)
final class NTPHeader: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPHeaderViewModel?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        // Create a placeholder hosting controller - will be configured later
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hostingController.view)
        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    func configure(with viewModel: NTPHeaderViewModel,
                   windowUUID: WindowUUID) {
        self.viewModel = viewModel

        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPHeaderView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        hostingController?.rootView = AnyView(swiftUIView)
    }
}

// MARK: - SwiftUI Multi-Purpose Header View
@available(iOS 16.0, *)
struct NTPHeaderView: View {
    @ObservedObject var viewModel: NTPHeaderViewModel
    let windowUUID: WindowUUID
    // Use explicit SwiftUI.Environment to avoid ambiguity
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool

    var body: some View {
        HStack(spacing: .ecosia.space._1s) {
            Spacer()
            if AISearchMVPExperiment.isEnabled {
                EcosiaAISearchButton(
                    windowUUID: windowUUID,
                    onTap: handleAISearchTap
                )
            }
            ZStack(alignment: .topLeading) {
                EcosiaAccountNavButton(
                    seedCount: viewModel.seedCount,
                    avatarURL: viewModel.userAvatarURL,
                    backgroundColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.backgroundElevation1),
                    textColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.textPrimary),
                    enableAnimation: !reduceMotion,
                    onTap: handleTap
                )

                // Balance increment indicator positioned above-left of counter
                if let increment = viewModel.balanceIncrement {
                    BalanceIncrementAnimationView(
                        increment: increment,
                        textColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.textPrimary),
                        backgroundColor: Color(EcosiaColor.Peach100)
                    )
                    .offset(x: 20, y: -10) // Position above-left of the counter number
                }
            }
        }
        .padding(.leading, .ecosia.space._m)
        .padding(.trailing, .ecosia.space._m)
        .onAppear {
            viewModel.registerVisitIfNeeded()
        }
    }

    private func handleAISearchTap() {
        viewModel.openAISearch()
    }

    private func handleTap() {
        if viewModel.isLoggedIn {
            viewModel.performLogout()
        } else {
            viewModel.performLogin()
        }
    }
}
