// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Ecosia

extension SimpleToast {

    enum AccessoryImage {
        case named(String), view(UIView)
    }

    @discardableResult
    // Ecosia: Migrated to be able to customize the accessory image shown, as well as bottom inset
    func ecosiaShowAlertWithText(
        _ text: String,
        image: AccessoryImage? = nil,
        bottomContainer: UIView,
        theme: Theme,
        bottomInset: CGFloat? = nil
    ) -> SimpleToast {
        let toast = self.createView(text: text, image: image, theme: theme)
        toast.layer.cornerRadius = .ecosia.borderRadius._l
        toast.layer.masksToBounds = true

        bottomContainer.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        let toastHeightConstraint = toast.heightAnchor.constraint(equalToConstant: Toast.UX.toastHeightWithShadow)
        toastHeightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 16),
            toast.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -16),
            toast.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -((bottomInset ?? 0) + 12)),
            toastHeightConstraint
        ])
        // Ecosia: Inline animation since animate() is private in parent class
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - Toast.UX.toastHeightWithShadow
                frame.size.height = Toast.UX.toastHeightWithShadow
                toast.frame = frame
            },
            completion: { [weak toast, weak toastHeightConstraint] _ in
                // Ecosia: Task + sleep instead of DispatchQueue for strict concurrency (Toast.UX.toastDismissAfter = 4.5s)
                let voiceOverExtra: TimeInterval = UIAccessibility.isVoiceOverRunning ? 1.0 : 0.0
                let totalDelay: TimeInterval = 4.5 + voiceOverExtra
                Task { @MainActor in
                    // Ecosia: Use nanoseconds for iOS 15 compatibility (Task.sleep(for: .seconds) is iOS 16+)
                    try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
                    guard let toast = toast, let toastHeightConstraint = toastHeightConstraint else { return }
                    UIView.animate(
                        withDuration: Toast.UX.toastAnimationDuration,
                        animations: {
                            toastHeightConstraint.constant = 0
                            toast.superview?.layoutIfNeeded()
                        },
                        completion: { _ in
                            toast.removeFromSuperview()
                        }
                    )
                }
            }
        )
        return self
    }

    fileprivate func createView(text: String,
                                image: AccessoryImage?,
                                theme: Theme) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = .ecosia.space._1s
        stack.layer.cornerRadius = .ecosia.borderRadius._l
        stack.backgroundColor = theme.colors.ecosia.buttonBackgroundPrimaryActive

        let toast = UILabel()
        toast.text = text
        toast.numberOfLines = 1
        toast.textColor = theme.colors.ecosia.textInversePrimary
        // Ecosia: Use consistent font style with main implementation
        toast.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 17)
        toast.adjustsFontForContentSizeCategory = true
        toast.adjustsFontSizeToFitWidth = true
        toast.textAlignment = .left
        toast.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let leftSpace = UIView()
        leftSpace.widthAnchor.constraint(equalToConstant: .ecosia.space._1s).isActive = true
        stack.addArrangedSubview(leftSpace)
        stack.addArrangedSubview(toast)
        let rightSpace = UIView()
        rightSpace.widthAnchor.constraint(equalToConstant: .ecosia.space._1s).isActive = true
        stack.addArrangedSubview(rightSpace)

        if let image {
            let imageView: UIView

            switch image {
            case let .named(name):
                imageView = UIImageView(image: .init(named: name)?.withRenderingMode(.alwaysTemplate))
                imageView.tintColor = theme.colors.ecosia.iconInverseStrong
                imageView.contentMode = .scaleAspectFit
                imageView.setContentHuggingPriority(.required, for: .horizontal)
            case let .view(view):
                imageView = view
            }

            stack.insertArrangedSubview(imageView, at: 1)
        }

        return stack
    }
}
