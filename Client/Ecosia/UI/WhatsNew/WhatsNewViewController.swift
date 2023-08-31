// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class WhatsNewViewController: UIViewController {
    
    private var viewModel: WhatsNewViewModel!
    private var knob = UIView()
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
        knob.layer.cornerRadius = 2

        closeButton.setTitle("Close", for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        headerLabel.text = .localized(.whatsNewViewTitle)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WhatsNewCell.self, forCellReuseIdentifier: WhatsNewCell.reuseIdentifier)
        
        footerButton.setTitle(.localized(.whatsNewFooterButtonTitle), for: .normal)
        footerButton.translatesAutoresizingMaskIntoConstraints = false
        footerButton.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)
        
        view.addSubview(knob)
        view.addSubview(closeButton)
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        view.addSubview(footerButton)
    }
    
    private func layoutViews() {
        
        // Knob view constraints
        NSLayoutConstraint.activate([
            knob.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            knob.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            knob.widthAnchor.constraint(equalToConstant: 32),
            knob.heightAnchor.constraint(equalToConstant: 4)
        ])

        // Close button constraints
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        // Header label constraints
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Table view constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Footer button constraints
        NSLayoutConstraint.activate([
            footerButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 10),
            footerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func footerButtonTapped() {
        // TODO: Implement your navigation logic
    }
}

extension WhatsNewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WhatsNewCell", for: indexPath) as! WhatsNewCell
        let item = viewModel.items[indexPath.row]
        cell.configure(with: item, images: images)
        return cell
    }
}

extension WhatsNewViewController: UITableViewDelegate {
    // Implement your delegate methods here
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
//
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
        tableView.separatorColor = .theme.ecosia.border
        knob.backgroundColor = .theme.ecosia.secondaryText
    }
}
