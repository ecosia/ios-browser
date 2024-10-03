/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SwiftUI
import Core
import Common

protocol NTPSeedCounterDelegate: NSObject {
    func didTapSeedCounter()
}

final class NTPSeedCounterCell: UICollectionViewCell, Themeable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let cornerRadius: CGFloat = 24
        static let containerWidthHeight: CGFloat = 48
        static let insetMargin: CGFloat = 16
    }
    
    // MARK: - Properties
    private var hostingController: UIHostingController<SeedCounterView>?
    private var containerStackView = UIStackView()
    weak var delegate: NTPSeedCounterDelegate?
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Setup
    
    private func setup() {
        contentView.addSubview(containerStackView)
        setupContainerStackView()
        setupSeedCounterViewHostingController()
        applyTheme()
        listenForThemeChange(contentView)
    }
    
    // MARK: - Action
    
    @objc private func openClimateImpactCounter() {
        delegate?.didTapSeedCounter()
    }
    
    // MARK: - Theming
    @objc func applyTheme() {
        containerStackView.backgroundColor = .legacyTheme.ecosia.secondaryBackground
    }
}

// MARK: - Helpers

extension NTPSeedCounterCell {
    
    private func setupSeedCounterViewHostingController() {
        let swiftUIView = SeedCounterView(progressManagerType: UserDefaultsSeedProgressManager.self)
        hostingController = UIHostingController(rootView: swiftUIView)
        
        guard let hostingController else { return }
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        containerStackView.addArrangedSubview(hostingController.view)
    }
    
    private func setupContainerStackView() {
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.layer.masksToBounds = true
        containerStackView.layer.cornerRadius = UX.cornerRadius
        NSLayoutConstraint.activate([
            containerStackView.heightAnchor.constraint(equalToConstant: UX.containerWidthHeight),
            containerStackView.widthAnchor.constraint(equalToConstant: UX.containerWidthHeight),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin)
        ])
    }
}
