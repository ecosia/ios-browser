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
        static let twinkleSizeOffset: CGFloat = 16
    }
    
    // MARK: - Properties
    private var hostingController: UIHostingController<SeedCounterView>?
    private var containerStackView = UIStackView()
    weak var delegate: NTPSeedCounterDelegate?
    private var sparklesAnimationDuration: Double {
        SeedCounterNTPExperiment.sparklesAnimationDuration
    }
    // Transparent button and TwinkleView
    private var button: UIButton = UIButton()
    private var twinkleHostingController: UIHostingController<TwinkleView>?
    private var isTwinkleActive: Bool = false
    
    // MARK: - Themeable Properties
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        listenForLevelUpNotification()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UserDefaultsSeedProgressManager.levelUpNotification, object: nil)
    }
    
    // MARK: - Setup
    
    private func setup() {
        contentView.addSubview(containerStackView)
        setupContainerStackView()
        setupSeedCounterViewHostingController()
        setupTransparentButton()
        setupTwinkleViewHostingController()
        applyTheme()
        listenForThemeChange(contentView)
    }
    
    private func setupTransparentButton() {
        // Transparent button to make the entire stack view tappable
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(openClimateImpactCounter), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            button.topAnchor.constraint(equalTo: containerStackView.topAnchor),
            button.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor)
        ])
    }

    private func setupTwinkleViewHostingController() {
        let twinkleView = TwinkleView(active: isTwinkleActive)
        twinkleHostingController = UIHostingController(rootView: twinkleView)
        
        guard let twinkleHostingController else { return }
        
        // Setup TwinkleView hosting
        twinkleHostingController.view.backgroundColor = .clear
        twinkleHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        twinkleHostingController.view.isUserInteractionEnabled = false
        twinkleHostingController.view.clipsToBounds = true
        contentView.addSubview(twinkleHostingController.view)
        
        // Add a 16-point offset around the TwinkleView
        NSLayoutConstraint.activate([
            twinkleHostingController.view.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: -UX.twinkleSizeOffset),
            twinkleHostingController.view.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: UX.twinkleSizeOffset),
            twinkleHostingController.view.topAnchor.constraint(equalTo: containerStackView.topAnchor, constant: -UX.twinkleSizeOffset),
            twinkleHostingController.view.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: UX.twinkleSizeOffset)
        ])
    }

    private func setupSeedCounterViewHostingController() {
        let swiftUIView = SeedCounterView(progressManagerType: SeedCounterNTPExperiment.progressManagerType.self)
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
    
    // MARK: - Twinkle helpers
    
    // Trigger the twinkle animation on level-up
    func triggerTwinkleEffect() {
        isTwinkleActive = true
        updateTwinkleView()

        // Automatically stop showing twinkle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + sparklesAnimationDuration) {
            self.isTwinkleActive = false
            self.updateTwinkleView()
        }
    }

    // Update the TwinkleView based on `isTwinkleActive`
    private func updateTwinkleView() {
        twinkleHostingController?.rootView = TwinkleView(active: isTwinkleActive)
    }
    
    // MARK: - Observer
    
    private func listenForLevelUpNotification() {
        // Listen for the level-up notification
        NotificationCenter.default.addObserver(forName: UserDefaultsSeedProgressManager.levelUpNotification, object: nil, queue: .main) { [weak self] _ in
            self?.triggerTwinkleEffect()
        }
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
