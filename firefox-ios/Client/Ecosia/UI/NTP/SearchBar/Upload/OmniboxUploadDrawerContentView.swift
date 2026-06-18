// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class OmniboxUploadDrawerContentView: UIView {

    private enum UX {
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberTopPadding: CGFloat = .ecosia.space._1s
        static let contentTopPadding: CGFloat = .ecosia.space._l
        static let contentBottomPadding: CGFloat = .ecosia.space._2l
        static let horizontalPadding: CGFloat = .ecosia.space._2l
        static let optionSpacing: CGFloat = .ecosia.space._m
    }

    private let grabberView: UIView = .build { view in
        view.layer.cornerRadius = UX.grabberHeight / 2
        view.isAccessibilityElement = false
    }

    private let optionsStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .top
        stack.spacing = UX.optionSpacing
    }

    private(set) var optionViews: [OmniboxUploadOptionView] = []

    var onOptionSelected: ((OmniboxUploadOption) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.cornerRadius = .ecosia.borderRadius._1l
        clipsToBounds = true
        isAccessibilityElement = false
        accessibilityElements = []

        addSubview(grabberView)
        addSubview(optionsStack)

        OmniboxUploadOption.allCases.forEach { option in
            let optionView = OmniboxUploadOptionView(option: option)
            optionView.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            optionViews.append(optionView)
            optionsStack.addArrangedSubview(optionView)
        }

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: topAnchor, constant: UX.grabberTopPadding),
            grabberView.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: UX.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: UX.grabberHeight),

            optionsStack.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: UX.contentTopPadding),
            optionsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalPadding),
            optionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalPadding),
            optionsStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -UX.contentBottomPadding)
        ])
    }

    @objc private func optionTapped(_ sender: OmniboxUploadOptionView) {
        onOptionSelected?(sender.option)
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.ecosia.backgroundElevation2
        grabberView.backgroundColor = theme.colors.ecosia.borderDecorative
        optionViews.forEach { $0.applyTheme(theme: theme) }
        accessibilityElements = optionViews
    }
}
