// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

protocol NTPAIActionsCellDelegate: AnyObject {
    func aiActionsCellDidRequestAISearch()
}

/// NTP cell containing AI-related actions like AI search
@available(iOS 16.0, *)
final class NTPAIActionsCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPAIActionsCellViewModel?

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

    func configure(with viewModel: NTPAIActionsCellViewModel, windowUUID: WindowUUID) {
        self.viewModel = viewModel

        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPAIActionsCellView(
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

// MARK: - SwiftUI AI Actions Cell View
@available(iOS 16.0, *)
struct NTPAIActionsCellView: View {
    @ObservedObject var viewModel: NTPAIActionsCellViewModel
    let windowUUID: WindowUUID

    // Use explicit SwiftUI.Environment to avoid ambiguity
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager

    var body: some View {
        HStack {
            Spacer()
            
            // AI Search Button positioned on the right
            EcosiaAISearchButton(
                backgroundColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.backgroundElevation1),
                iconColor: Color(themeManager.getCurrentTheme(for: windowUUID).colors.ecosia.textPrimary),
                onTap: handleAISearchTap
            )
        }
        .padding(.leading, .ecosia.space._m)
        .padding(.trailing, .ecosia.space._m)
    }
    
    private func handleAISearchTap() {
        viewModel.openAISearch()
    }
}