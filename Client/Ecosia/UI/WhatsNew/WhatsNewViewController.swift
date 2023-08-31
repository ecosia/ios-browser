// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class WhatsNewViewController: UIViewController {
    
    // MARK: - UX
    
    private struct UX {
        private init() {}
        static let defaultPadding: CGFloat = 16

        struct ForestAndWaves {
            private init() {}
            static let waveHeight: CGFloat = 34
            static let forestOffsetTypePad: CGFloat = 38
            static let forestOffsetTypePhone: CGFloat = 26
            static let forestHeightTypePad: CGFloat = 135
            static let forestWidthTypePad: CGFloat = 544
            static let forestTopMargin: CGFloat = 24
        }
        
        struct Knob {
            private init() {}
            static let height: CGFloat = 4
            static let width: CGFloat = 32
            static let cornerRadious: CGFloat = 2
        }

        struct CloseButton {
            private init() {}
            static let size: CGFloat = 32
            static let distanceFromCardBottom: CGFloat = 32
        }
    }
    
    // MARK: - Properties
    
    private var viewModel: WhatsNewViewModel!
    private let knob = UIView()
    private let firstImageView = UIImageView(image: .init(named: "whatsNewTrees"))
    private let secondImageView = UIImageView(image: .init(named: "waves"))
    private let closeButton = UIButton()
    private let headerLabel = UILabel()
    private let containerView = UIView()
    private let tableView = UITableView()
    private let footerButton = UIButton()
    private let images = Images(.init(configuration: .ephemeral))
    
    init(viewModel: WhatsNewViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
        applyTheme()
        tableView.reloadData()
    }
    
    private func setupViews() {
        
        knob.translatesAutoresizingMaskIntoConstraints = false
        knob.layer.cornerRadius = UX.Knob.cornerRadious

        closeButton.setImage(UIImage(named: "xmark"), for: .normal)
        closeButton.imageView?.contentMode = .scaleAspectFill
        closeButton.layer.cornerRadius = UX.CloseButton.size/2
        closeButton.contentVerticalAlignment = .fill
        closeButton.contentHorizontalAlignment = .fill
        closeButton.imageEdgeInsets = UIEdgeInsets(equalInset: 10)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        headerLabel.text = .localized(.whatsNewViewTitle)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        firstImageView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(firstImageView)
        containerView.insertSubview(secondImageView, aboveSubview: firstImageView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(WhatsNewCell.self, forCellReuseIdentifier: WhatsNewCell.reuseIdentifier)
        
        footerButton.setTitle(.localized(.whatsNewFooterButtonTitle), for: .normal)
        footerButton.translatesAutoresizingMaskIntoConstraints = false
        footerButton.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)
        
        view.addSubview(knob)
        view.addSubview(closeButton)
        view.addSubview(containerView)
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        view.addSubview(footerButton)
    }
    
    private func layoutViews() {
        
        NSLayoutConstraint.activate([
            // Knob view constraints
            knob.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.defaultPadding/2),
            knob.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            knob.widthAnchor.constraint(equalToConstant: UX.Knob.width),
            knob.heightAnchor.constraint(equalToConstant: UX.Knob.height),
            
            // Close button constraints
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UX.defaultPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.defaultPadding),
            closeButton.heightAnchor.constraint(equalToConstant: UX.CloseButton.size),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),

            // Container View Constraints
            containerView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: -UX.defaultPadding),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // First image view constraints
            firstImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            firstImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            firstImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Second image view constraints
            secondImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            secondImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            secondImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            secondImageView.heightAnchor.constraint(equalToConstant: UX.ForestAndWaves.waveHeight),

            // Header label constraints
            headerLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: UX.defaultPadding),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: UX.defaultPadding),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Footer button constraints
            footerButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: UX.defaultPadding),
            footerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UX.defaultPadding),
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func footerButtonTapped() {
        closeButtonTapped()
    }
}

extension WhatsNewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WhatsNewCell.reuseIdentifier, for: indexPath) as! WhatsNewCell
        let item = viewModel.items[indexPath.row]
        cell.configure(with: item, images: images)
        return cell
    }
}

extension WhatsNewViewController {
    
    static func presentSheetOn(_ viewController: UIViewController) {
        
        // main menu should only be opened from the browser
        guard let browser = viewController as? BrowserViewController else { return }
        let sheet = WhatsNewViewController(viewModel: WhatsNewViewModel(provider: LocalDataProvider()))
        sheet.modalPresentationStyle = .automatic
//
        // iPhone
        if #available(iOS 15.0, *), let sheet = sheet.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

//        // ipad
//        if let popoverVC = sheet.popoverPresentationController, sheet.modalPresentationStyle == .popover {
//            popoverVC.delegate = viewController
//            popoverVC.sourceView = view
//            popoverVC.sourceRect = view.bounds
//
//            let trait = viewController.traitCollection
//            if viewModel.isMainMenu {
//                let margins = viewModel.getMainMenuPopOverMargins(trait: trait, view: view, presentedOn: viewController)
//                popoverVC.popoverLayoutMargins = margins
//            }
//            popoverVC.permittedArrowDirections = [.up]
//        }
        
        viewController.present(sheet, animated: true, completion: nil)
    }

}

// MARK: - NotificationThemeable

extension WhatsNewViewController: NotificationThemeable {

    func applyTheme() {
        view.backgroundColor = .theme.ecosia.modalBackground
        tableView.backgroundColor = .theme.ecosia.modalBackground
        tableView.separatorColor = .clear
        knob.backgroundColor = .theme.ecosia.secondaryText
        closeButton.backgroundColor = .theme.ecosia.primaryBackground
        closeButton.tintColor = .theme.ecosia.actionSheetCancelButton
    }
}
