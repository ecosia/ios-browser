// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

protocol APNConsentViewDelegate: AnyObject {
    func apnConsentViewDidShow(_ viewController: APNConsentViewController)
}

final class APNConsentViewController: UIViewController {
    
    // MARK: - UX
    
    private struct UX {
        private init() {}
        static let defaultPadding: CGFloat = 16

        struct PreferredContentSize {
            private init() {}
            static let iPadWidth: CGFloat = 544
            static let iPadHeight: CGFloat = 600
            static let iPhoneCustomDetentHeight: CGFloat = 560
        }
        
        struct Waves {
            private init() {}
            static let waveHeight: CGFloat = 34
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
        
        struct FooterButton {
            private init() {}
            static let height: CGFloat = 50
        }
    }
    
    // MARK: - Properties
    
    private var viewModel: APNConsentViewModelProtocol!
    private var firstImageView = UIImageView()
    private let secondImageView = UIImageView(image: .init(named: "waves"))
    private let headerLabel = UILabel()
    private let topContainerView = UIView()
    private let headerLabelContainerView = UIView()
    private let tableView = UITableView()
    private let footerButton = UIButton()
    weak var delegate: APNConsentViewDelegate?

    // MARK: - Init

    init(viewModel: APNConsentViewModelProtocol, delegate: APNConsentViewDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
        applyTheme()
        updateTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modalTransitionStyle = .crossDissolve
        self.delegate?.apnConsentViewDidShow(self)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

// MARK: - Buttons Actions

extension APNConsentViewController {
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func footerButtonTapped() {
        closeButtonTapped()
    }
}

// MARK: - View Setup Helpers

extension APNConsentViewController {
    
    private func setupViews() {
        
        firstImageView = UIImageView(image: viewModel.image)
        firstImageView.translatesAutoresizingMaskIntoConstraints = false

        headerLabelContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = viewModel.title
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = .preferredFont(forTextStyle: .title3).bold()
        headerLabelContainerView.addSubview(headerLabel)

        topContainerView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.translatesAutoresizingMaskIntoConstraints = false
        topContainerView.addSubview(firstImageView)
        topContainerView.insertSubview(secondImageView, aboveSubview: firstImageView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(APNConsentItemCell.self, forCellReuseIdentifier: APNConsentItemCell.cellIdentifier)
        
        footerButton.setTitle(viewModel.ctaAllowButtonTitle, for: .normal)
        footerButton.translatesAutoresizingMaskIntoConstraints = false
        footerButton.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)
        footerButton.layer.cornerRadius = UX.FooterButton.height/2
        
        view.addSubview(topContainerView)
        view.addSubview(headerLabelContainerView)
        view.addSubview(tableView)
        view.addSubview(footerButton)
    }
    
    private func layoutViews() {
        
        NSLayoutConstraint.activate([
            
            // Top Container View Constraints
            topContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            topContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // First image view constraints
            firstImageView.topAnchor.constraint(equalTo: topContainerView.topAnchor),
            firstImageView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            firstImageView.centerXAnchor.constraint(equalTo: topContainerView.centerXAnchor),

            // Second image view constraints
            secondImageView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            secondImageView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            secondImageView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            secondImageView.heightAnchor.constraint(equalToConstant: UX.Waves.waveHeight),

            // Header Label Container View Constraints
            headerLabelContainerView.topAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            headerLabelContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabelContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Header label constraints
            headerLabel.topAnchor.constraint(equalTo: headerLabelContainerView.topAnchor, constant: UX.defaultPadding),
            headerLabel.bottomAnchor.constraint(equalTo: headerLabelContainerView.bottomAnchor, constant: -UX.defaultPadding),
            headerLabel.centerXAnchor.constraint(equalTo: headerLabelContainerView.centerXAnchor),

            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerLabelContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerButton.topAnchor),
            
            // Footer button constraints
            footerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UX.defaultPadding),
            footerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.defaultPadding),
            footerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.defaultPadding),
            footerButton.heightAnchor.constraint(equalToConstant: UX.FooterButton.height)
        ])
    }
    
    private func updateTableView() {
        tableView.reloadData()
    }
}

// MARK: - TableView Data Source

extension APNConsentViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.listItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: APNConsentItemCell.cellIdentifier, for: indexPath) as! APNConsentItemCell
        let item = viewModel.listItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - NotificationThemeable

extension APNConsentViewController: NotificationThemeable {

    func applyTheme() {
        view.backgroundColor = .theme.ecosia.primaryBackground
        topContainerView.backgroundColor = .theme.ecosia.tertiaryBackground
        tableView.backgroundColor = .theme.ecosia.primaryBackground
        tableView.separatorColor = .clear
        footerButton.backgroundColor = .theme.ecosia.primaryBrand
        footerButton.setTitleColor(.theme.ecosia.primaryTextInverted, for: .normal)
        headerLabelContainerView.backgroundColor = .theme.ecosia.primaryBackground
        secondImageView.tintColor = .theme.ecosia.primaryBackground
    }
}

// MARK: - Presentation

extension APNConsentViewController {
    
    static func presentOn(_ viewController: UIViewController,
                          viewModel: APNConsentViewModelProtocol) {
        
        guard let whatsNewDelegateViewController = viewController as? APNConsentViewDelegate else { return }
        let sheet = APNConsentViewController(viewModel: viewModel,
                                           delegate: whatsNewDelegateViewController)
        sheet.modalPresentationStyle = .automatic
        
        // iPhone
        if #available(iOS 16.0, *), let sheet = sheet.sheetPresentationController {
            let custom = UISheetPresentationController.Detent.custom { context in
                return UX.PreferredContentSize.iPhoneCustomDetentHeight
            }
            sheet.detents = [custom, .large()]
        } else if #available(iOS 15.0, *), let sheet = sheet.sheetPresentationController {
            sheet.detents = [.large()]
        }

        // iPad
        if sheet.traitCollection.userInterfaceIdiom == .pad {
            sheet.modalPresentationStyle = .formSheet
            sheet.preferredContentSize = .init(width: UX.PreferredContentSize.iPadWidth,
                                         height: UX.PreferredContentSize.iPadHeight)
        }
        
        viewController.present(sheet, animated: true, completion: nil)
    }
}
