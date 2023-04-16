// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class LockerButton: UIButton {
    
    enum LockerButtonStatus {
        case locked
        case lockedEnhanced
        case unlocked
        case unavailable
    }

    // MARK: - Variables
    
    private var lockerStatus: LockerButtonStatus = .locked {
        didSet {
            updateButtonImageAccordingToStatus()
        }
    }
    
    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

extension LockerButton {
    
    private func configureView() {
        clipsToBounds = false
        imageView?.contentMode = .center
        adjustsImageWhenHighlighted = false
        imageEdgeInsets = .init(top: 0, left: 10, bottom: 0, right: 0)
    }
    
    func updateState(_ lockerStatus: LockerButtonStatus) {
        self.lockerStatus = lockerStatus
    }
    
    private func updateButtonImageAccordingToStatus() {
        let lockerLockedImage = UIImage.templateImageNamed("lock_verified")
        let lockerUnlockedImage = UIImage.templateImageNamed("lock_blocked")
        let lockerUnavailableImage = UIImage.init(imageLiteralResourceName: "lock_blocked_dark")

        switch lockerStatus {
        case .locked:
            setImage(lockerLockedImage, for: .normal)
            imageView?.tintColor = .theme.ecosia.disabled
        case .lockedEnhanced:
            setImage(lockerLockedImage, for: .normal)
            imageView?.tintColor = .theme.ecosia.primaryButtonActive
        case .unlocked:
            setImage(lockerUnlockedImage, for: .normal)
            imageView?.tintColor = .theme.ecosia.disabled
        case .unavailable:
            setImage(lockerUnavailableImage, for: .normal)
        }
    }
}
