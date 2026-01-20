// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A custom transition delegate that provides a fade animation for modal presentation and dismissal
public final class FadeTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    /// The background color to apply to the underlying view when dismissing. Defaults to nil (no change).
    public var dismissalBackgroundColor: UIColor?

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeAnimator(isPresenting: false, dismissalBackgroundColor: dismissalBackgroundColor)
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeAnimator(isPresenting: true, dismissalBackgroundColor: nil)
    }
}

private final class FadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let dismissalBackgroundColor: UIColor?

    init(isPresenting: Bool, dismissalBackgroundColor: UIColor?) {
        self.isPresenting = isPresenting
        self.dismissalBackgroundColor = dismissalBackgroundColor
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

            UIView.animate(withDuration: duration,
                           animations: {
                toView.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            containerView.insertSubview(toView, at: 0)
            toView.alpha = 1

            if let dismissalBackgroundColor = dismissalBackgroundColor {
                toView.backgroundColor = dismissalBackgroundColor
            }

            UIView.animate(withDuration: duration,
                           animations: {
                fromView.alpha = 0
            }, completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            })
        }
    }
}
