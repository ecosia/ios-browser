// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Core

struct CompanyJoinedAlertViewController: UIViewControllerRepresentable {
    var companyName: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let hostingController = UIHostingController(rootView: CompanyJoinedAlertView(companyName: companyName, isPresented: $isPresented))
        hostingController.view.backgroundColor = .clear // Ensure the SwiftUI view has a clear background
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if !isPresented {
            uiViewController.dismiss(animated: true, completion: nil)
        }
    }
}

extension UIViewController {
    func presentCompanyAlert(for company: Company) {
        let isAlertPresented = Binding<Bool>(
            get: { return true },
            set: { newValue in
                if !newValue {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        )
        let companyAlertVC = CompanyJoinedAlertViewController(companyName: company.name, isPresented: isAlertPresented)

        let alertVC = UIViewController()
        alertVC.view.backgroundColor = .clear // Ensure the alert view controller background is clear
        let hostingController = UIHostingController(rootView: companyAlertVC)
        hostingController.view.backgroundColor = .clear
        alertVC.addChild(hostingController)
        alertVC.view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: alertVC.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: alertVC.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: alertVC.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: alertVC.view.bottomAnchor)
        ])

        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        present(alertVC, animated: true)
    }
}
