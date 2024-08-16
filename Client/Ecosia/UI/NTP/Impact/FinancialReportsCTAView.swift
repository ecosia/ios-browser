// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary

final class FinancialReportsCTAView: UIView, Themeable {
    struct UX {
        static let cornerRadius: CGFloat = 10
        static let padding: CGFloat = 16
    }
    
    private lazy var actionButton: ResizableButton = {
        let button = ResizableButton()
        button.setTitle(.localized(.climateImpactCTAExperimentText), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.contentHorizontalAlignment = .left
        button.buttonEdgeSpacing = 0
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()
    
    weak var delegate: NTPImpactCellDelegate?
    
    // MARK: - Themeable Properties
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    init() {
        super.init(frame: .zero)
        
        addSubview(actionButton)
        
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = UX.cornerRadius
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding),
            actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.padding),
        ])
        
        applyTheme()
    }
    
    required init?(coder: NSCoder) { nil }
    
    func applyTheme() {
        backgroundColor = .legacyTheme.ecosia.secondaryBackground
        actionButton.setTitleColor(.legacyTheme.ecosia.primaryButton, for: .normal)
    }
    
    @objc private func buttonAction() {
        Analytics.shared.ntp(.click, label: .climateImpactCTA)
        delegate?.openFinancialReports()
    }
}
