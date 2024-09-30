/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
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
        static let imageWidthHeight: CGFloat = 24
    }
    
    // MARK: - Properties
    
    private let seedCounter = UIImageView(image: .init(named: "seedIcon"))
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
        
        containerStackView.axis = .horizontal
        containerStackView.alignment = .center
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.heightAnchor.constraint(equalToConstant: UX.containerWidthHeight).isActive = true
        containerStackView.widthAnchor.constraint(equalToConstant: UX.containerWidthHeight).isActive = true
        containerStackView.layer.masksToBounds = true
        containerStackView.layer.cornerRadius = UX.cornerRadius
        containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: -UX.insetMargin).isActive = true

        seedCounter.translatesAutoresizingMaskIntoConstraints = false
        seedCounter.clipsToBounds = true
        seedCounter.contentMode = .scaleAspectFit
        seedCounter.heightAnchor.constraint(equalToConstant: UX.imageWidthHeight).isActive = true
        seedCounter.widthAnchor.constraint(equalToConstant: UX.imageWidthHeight).isActive = true
        
        containerStackView.addArrangedSubview(seedCounter)
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
