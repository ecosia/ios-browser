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
final class NTPMultiPurposeEcosiaHeader: UICollectionViewCell, ReusableCell {
    
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
    
    func configure(with viewModel: NTPMultiPurposeEcosiaHeaderViewModel,
                   windowUUID: WindowUUID) {
        self.viewModel = viewModel
        
        // Update the SwiftUI view with the new view model
        let swiftUIView = NTPMultiPurposeEcosiaHeaderView(
            viewModel: viewModel,
            windowUUID: windowUUID,
        )
        
        hostingController?.rootView = AnyView(swiftUIView)
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
            EcosiaAISearchButton(
                windowUUID: windowUUID,
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
