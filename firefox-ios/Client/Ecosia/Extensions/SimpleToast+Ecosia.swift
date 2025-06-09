// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

extension SimpleToast {

    enum AccessoryImage {
        case named(String), view(UIView)
    }

    @discardableResult
    // Ecosia: Migrated to be able to customize the accessory image shown, as well as bottom inset
    func showAlertWithText(
        _ text: String,
        image: AccessoryImage,
        bottomContainer: UIView,
        theme: Theme,
        bottomInset: CGFloat? = nil
    ) -> SimpleToast {
        let toast = self.createView(text: text, image: image, theme: theme)
        // Ecosia: Use standardCornerRadius from UX
        toast.layer.cornerRadius = UX.standardCornerRadius
        toast.layer.masksToBounds = true

        bottomContainer.addSubview(toast)
        toast.snp.makeConstraints { (make) in
            make.left.equalTo(bottomContainer).offset(CGFloat(16))
            make.right.equalTo(bottomContainer).offset(-CGFloat(16))
            make.height.equalTo(Toast.UX.toastHeight)
            make.bottom.equalTo(bottomContainer).offset(-((bottomInset ?? 0) + CGFloat(12)))
        }
        animate(toast)
        return self
    }

    fileprivate func createView(text: String,
                                image: AccessoryImage,
                                theme: Theme) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        // Ecosia: Use padding from UX
        stack.spacing = UX.padding
        // Ecosia: Use standardCornerRadius from UX
        stack.layer.cornerRadius = UX.standardCornerRadius
        stack.backgroundColor = theme.colors.ecosia.backgroundQuaternary

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

        let imageView: UIView

        switch image {
        case let .named(name):
            imageView = UIImageView(image: .init(named: name)?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = theme.colors.ecosia.toastImageTint
            imageView.contentMode = .scaleAspectFit
            imageView.setContentHuggingPriority(.required, for: .horizontal)
        case let .view(view):
            imageView = view
        }

        let leftSpace = UIView()
        // Ecosia: Use padding from UX
        leftSpace.widthAnchor.constraint(equalToConstant: UX.padding).isActive = true
        stack.addArrangedSubview(leftSpace)
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(toast)
        let rightSpace = UIView()
        // Ecosia: Use padding from UX
        rightSpace.widthAnchor.constraint(equalToConstant: UX.padding).isActive = true
        stack.addArrangedSubview(rightSpace)
        return stack
    }
}
