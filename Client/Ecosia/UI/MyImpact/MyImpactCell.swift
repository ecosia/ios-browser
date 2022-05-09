/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/*
 private var referralImpactCellModel: MyImpactCellModel {
     let callout = MyImpactCellModel.Callout(text: .localized(.myImpactDescription),
                                             button: .localized(.learnMore),
                                             selector: #selector(learnMore),
                                             collapsed: true)
     let top = MyImpactStackViewModel(title: "\(User.shared.impact)",
                                      highlight: true, subtitle: .localized(.myTrees),
                                      imageName: "personalCounter")

     let middle = MyImpactStackViewModel(title: .localizedPlural(.treesPlural, num: User.shared.searchImpact),
                                         highlight: false,
                                         subtitle: .localizedPlural(.searches, num: personalCounter.state!),
                                         imageName: "impactSearch")

     let bottom = MyImpactStackViewModel(title: .localizedPlural(.treesPlural, num: User.shared.referrals.impact),
                                         highlight: false,
                                         subtitle: .localizedPlural(.referrals, num: User.shared.referrals.count),
                                         imageName: "impactReferrals")

     return MyImpactCellModel(top: top, middle: middle, bottom: bottom, callout: callout)
 }
 */

final class MyImpactCell: UICollectionViewCell, AutoSizingCell, Themeable {
    private weak var totalProgress: Progress!
    private weak var currentProgress: Progress!
    private weak var widthConstraint: NSLayoutConstraint!
    private weak var outline: UIView!
    
    required init?(coder: NSCoder) { nil }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let outline = UIView()
        outline.layer.cornerRadius = 10
        outline.translatesAutoresizingMaskIntoConstraints = false
        self.outline = outline
        contentView.addSubview(outline)
        
        let totalProgress = Progress()
        self.totalProgress = totalProgress
        outline.addSubview(totalProgress)
        
        let currentProgress = Progress()
        currentProgress.value = 0.25
        self.currentProgress = currentProgress
        outline.addSubview(currentProgress)

//        let container = UIStackView()
//        container.distribution = .fill
//        container.axis = .vertical
//        container.spacing = 20
//        container.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(container)
//        self.container = container

        outline.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        outline.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        outline.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12).isActive = true
        outline.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true

        let widthConstraint = outline.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint
        
        totalProgress.topAnchor.constraint(equalTo: outline.topAnchor, constant: 25).isActive = true
        totalProgress.centerXAnchor.constraint(equalTo: outline.centerXAnchor).isActive = true
        
        currentProgress.centerYAnchor.constraint(equalTo: totalProgress.centerYAnchor).isActive = true
        currentProgress.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true

        applyTheme()
    }
    
    func update() {
        //
        //        if let top = model.top {
        //            topStack.isHidden = false
        //            topStack.display(top, action: .arrow(collapsed: model.callout.collapsed))
        //        } else {
        //            topStack.isHidden = true
        //        }
        //
        //        if let middle = model.middle {
        //            middleStack.isHidden = false
        //            middleStack.display(middle)
        //        } else {
        //            middleStack.isHidden = true
        //        }
        //
        //        if let bottom = model.bottom {
        //            bottomStack.isHidden = false
        //            bottomStack.display(bottom)
        //        } else {
        //            bottomStack.isHidden = true
        //        }
        //
        //        calloutButton.setTitle(model.callout.button, for: .normal)
        //        calloutLabel.text = model.callout.text
        //
        //        if model.callout.collapsed {
        //            calloutSeparatorConstraint.priority = .defaultHigh
        //            calloutContainerConstraint.isActive = false
        //            callout.alpha = 0
        //            separator.alpha = 1
        //        } else {
        //            calloutSeparatorConstraint.priority = .defaultLow
        //            calloutContainerConstraint.isActive = true
        //            callout.alpha =  1
        //            separator.alpha = 0
        //        }
    }

    func setWidth(_ width: CGFloat, insets: UIEdgeInsets) {
        let margin = max(max(16, insets.left), insets.right)
        widthConstraint.constant = width - 2 * margin
    }
    
    func applyTheme() {
        outline.backgroundColor = .theme.ecosia.ecosiaHomeCelBackground
        totalProgress.update(color: .theme.ecosia.treeCounterProgressTotal)
        currentProgress.update(color: .theme.ecosia.treeCounterProgressCurrent)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
