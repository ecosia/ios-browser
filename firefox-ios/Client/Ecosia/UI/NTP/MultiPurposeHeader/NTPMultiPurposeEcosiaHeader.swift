// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

protocol NTPMultiPurposeEcosiaHeaderDelegate: AnyObject {
    func multiPurposeEcosiaHeaderDidRequestAISearch()
}

/// NTP header cell containing multiple Ecosia-specific actions like AI search
@available(iOS 16.0, *)
final class NTPMultiPurposeEcosiaHeader: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPMultiPurposeEcosiaHeaderViewModel?

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

    func configure(with viewModel: NTPMultiPurposeEcosiaHeaderViewModel, windowUUID: WindowUUID) {
        self.viewModel = viewModel

        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPMultiPurposeEcosiaHeaderView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        hostingController?.rootView = AnyView(swiftUIView)
    }

    // MARK: - Theming
    func applyTheme(theme: Theme) {
        // Theme is handled by the SwiftUI view
    }
}

// MARK: - SwiftUI Multi-Purpose Header View
@available(iOS 16.0, *)
struct NTPMultiPurposeEcosiaHeaderView: View {
    @ObservedObject var viewModel: NTPMultiPurposeEcosiaHeaderViewModel
    let windowUUID: WindowUUID

    var body: some View {
        HStack {
            Spacer()
            
            // AI Search Button positioned on the right
            // Ecosia: Use theme colors from view model (following FeedbackView pattern)
            EcosiaAISearchButton(
                backgroundColor: viewModel.buttonBackgroundColor,
                iconColor: viewModel.buttonIconColor,
                onTap: handleAISearchTap
            )
        }
        .padding(.leading, .ecosia.space._m)
        .padding(.trailing, .ecosia.space._m)
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            // Ecosia: Listen to theme changes (following FeedbackView pattern)
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            let themeManager = AppContainer.shared.resolve() as ThemeManager
            viewModel.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }
    
    private func handleAISearchTap() {
        viewModel.openAISearch()
    }
}