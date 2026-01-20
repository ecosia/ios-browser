// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SwiftUI

public protocol WelcomeDelegate: AnyObject {
    func welcomeDidFinish(_ welcome: WelcomeViewController)
}

public final class WelcomeViewController: UIViewController {
    private weak var delegate: WelcomeDelegate?
    let windowUUID: WindowUUID

    required init?(coder: NSCoder) { nil }

    public init(delegate: WelcomeDelegate, windowUUID: WindowUUID) {
        self.delegate = delegate
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
        definesPresentationContext = true
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let swiftUIView = WelcomeView(
            windowUUID: windowUUID,
            onFinish: { [weak self] in
                guard let self = self else { return }
                self.delegate?.welcomeDidFinish(self)
            }
        )

        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
