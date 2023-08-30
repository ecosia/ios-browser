// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class WhatsNewViewController: UIViewController {
    
    private var viewModel: WhatsNewViewModel!
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
    }
    
    private func setupViews() {
        // Close Button
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Header
        headerLabel.text = .localized(.whatsNewViewTitle)
        headerLabel.textAlignment = .center
        
        // Table View
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WhatsNewCell.self, forCellReuseIdentifier: "WhatsNewCell")
        
        // Footer Button
        footerButton.setTitle("Learn More", for: .normal)
        footerButton.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)
        
        // Add to view
        view.addSubview(closeButton)
        view.addSubview(headerLabel)
        view.addSubview(containerView)
        view.addSubview(tableView)
        view.addSubview(footerButton)
        
    }
    
    private func layoutViews() {
        
    }
    
    @objc private func closeButtonTapped() {
        // Close the screen
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func footerButtonTapped() {
        // TO DO: Implement your navigation logic
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

final class WhatsNewCell: UITableViewCell {
    
    var contentConfiguration: UIListContentConfiguration?
    private var imageUrl: URL?

    func configure(with item: WhatsNewItem, images: Images) {
        imageUrl = item.imageUrl

        // Load the image asynchronously
        images.load(self, url: item.imageUrl) { [weak self] imageData in
            guard let self = self else { return }
            guard self.imageUrl == imageData.url else { return }
            let image = UIImage(data: imageData.data)

            // Configure based on iOS version
            if #available(iOS 14, *) {
                self.configureForiOS14(image: image, item: item)
            } else {
                self.configureForiOS13(image: image, item: item)
            }
        }
    }
    
    @available(iOS 14, *)
    private func configureForiOS14(image: UIImage?, item: WhatsNewItem) {
        var newConfiguration = defaultContentConfiguration().updated(for: self.traitCollection)
        newConfiguration.text = item.title
        newConfiguration.secondaryText = item.subtitle
        newConfiguration.image = image
        newConfiguration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        newConfiguration.imageProperties.cornerRadius = 8
        contentConfiguration = newConfiguration
    }
    
    private func configureForiOS13(image: UIImage?, item: WhatsNewItem) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.subtitle
        imageView?.image = image
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        if #available(iOS 14, *) {
            var updatedConfiguration = contentConfiguration?.updated(for: state.traitCollection)
            contentConfiguration = updatedConfiguration
        }
    }
}
