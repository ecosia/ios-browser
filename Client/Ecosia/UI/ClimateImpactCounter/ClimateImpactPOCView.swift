// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import SystemConfiguration
import Common

class ClimateImpactPOCView: UIViewController {
    
    let htmlString = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Your Impact</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f3f2ee;
        }

        /* Full screen green background */
        .green-background {
            background-color: #2f4f41;
            padding: 40px 20px;
            border-bottom-left-radius: 40px;
            border-bottom-right-radius: 40px;
        }

        /* Left align the title */
        .header {
            color: white;
            font-size: 28px;
            font-weight: bold;
            text-align: left;
        }

        .impact-container {
            background-color: white;
            margin-top: 20px;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }

        .progress {
            position: relative;
            margin-top: 20px;
        }

        .progress img {
            width: 100px;
        }

        .progress .status {
            font-size: 18px;
            margin-top: 10px;
            color: #333;
        }

        .progress .level {
            background-color: #1f7c41;
            color: white;
            border-radius: 12px;
            padding: 6px 12px;
            display: inline-block;
            margin-top: 10px;
            font-size: 14px;
        }

        .collectibles {
            background-color: #f3f2ee;
            margin-top: 20px;
            padding: 20px;
            border-radius: 12px;
        }

        .collectibles-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 18px;
        }

        .collectibles-header .unlock-btn {
            background-color: #333;
            color: white;
            padding: 8px 12px;
            border-radius: 20px;
            font-size: 12px;
        }

        .collectibles .seed-count {
            font-size: 14px;
            color: #777;
            margin-top: 12px;
        }

        .collectibles-items {
            display: flex;
            justify-content: space-between;
            margin-top: 20px;
        }

        .collectible-item {
            text-align: center;
            width: 80px;
        }

        .collectible-item img {
            width: 100%;
            border-radius: 8px;
        }

        .collectible-item .count {
            margin-top: 8px;
            font-size: 12px;
            color: #777;
        }

        .locked {
            position: relative;
        }

        .locked img {
            opacity: 0.6;
        }

        .locked::after {
            content: "🔒";
            position: absolute;
            top: 10px;
            left: 10px;
            font-size: 20px;
            color: white;
        }
    </style>
</head>
<body>

    <!-- Green background section -->
    <div class="green-background">
        <div class="header">Your Impact</div>
        <div class="impact-container">
            <div class="progress">
                <img src="https://via.placeholder.com/100x100" alt="Progress Image">
                <div class="status">1 / 3 Total seeds collected</div>
                <div class="level">Level 1 - Ecocurious</div>
            </div>
        </div>
    </div>

    <div class="collectibles">
        <div class="collectibles-header">
            <div>Collectibles</div>
            <button class="unlock-btn">Unlock at level 2</button>
        </div>
        <div class="seed-count">1 seed available</div>
        <div class="collectibles-items">
            <div class="collectible-item">
                <div class="locked">
                    <img src="https://via.placeholder.com/80x80" alt="Tree">
                </div>
                <div class="count">5</div>
            </div>
            <div class="collectible-item">
                <div class="locked">
                    <img src="https://via.placeholder.com/80x80" alt="Nut">
                </div>
                <div class="count">15</div>
            </div>
            <div class="collectible-item">
                <div class="locked">
                    <img src="https://via.placeholder.com/80x80" alt="Animal">
                </div>
                <div class="count">10</div>
            </div>
        </div>
    </div>

</body>
</html>
"""
    
    // Create the web view
    var webView: WKWebView!
    
    // Create the empty state view
    var emptyStateView: UIView!
    
    // Create the done button
    var doneButton: UIButton!
    
    // URL to load
    var urlString: String = "https://www.ecosia.org"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI
        setupWebView()
        setupDoneButton()
        
        // Check for network availability
        if isNetworkAvailable() {
            // loadWebView()
        } else {
            showEmptyState()
        }
    }
    
    // Remove the navigation bar for this view controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure navigation bar is hidden
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // Re-enable the navigation bar if returning to another view
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar if needed by the rest of the app
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // Setup the web view
    private func setupWebView() {
        webView = WKWebView(frame: .zero)
        webView.loadHTMLString(htmlString, baseURL: nil)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // WebView constraints
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Load the web content
    private func loadWebView() {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // Setup the done button
    private func setupDoneButton() {
        doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(dismissViewController), for: .touchUpInside)
        
        // Customize the appearance to mimic the right bar button item
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        
        view.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Done Button constraints
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
        ])
    }
    
    // Done button action to close the modal
    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    // Check for network availability
    private func isNetworkAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    // Show the empty state
    private func showEmptyState() {
        emptyStateView = UIView()
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)
        
        // ImageView for empty state
        let imageView = UIImageView(image: .init(named: "noInternet"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Label for empty state
        let label = UILabel()
        label.text = "No Network Connection"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view to hold image and label
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stackView)
        
        // Empty state view constraints
        NSLayoutConstraint.activate([
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // StackView constraints
            stackView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            
            // ImageView constraints (for size)
            imageView.heightAnchor.constraint(equalToConstant: 100),
            imageView.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
}
