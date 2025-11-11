// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A custom transition delegate that provides a fade animation for modal presentation and dismissal
final class FadeTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeAnimator(isPresenting: false)
    }

    func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeAnimator(isPresenting: true)
    }
}

private final class FadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        if isPresenting {
            containerView.addSubview(toView)
            toView.alpha = 0
            
            UIView.animate(withDuration: duration, animations: {
                toView.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            containerView.insertSubview(toView, at: 0)
            toView.alpha = 1
            UIView.animate(withDuration: duration, animations: {
                fromView.alpha = 0
            }, completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            })
        }
    }
}
