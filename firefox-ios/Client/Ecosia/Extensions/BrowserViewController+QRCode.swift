// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

// MARK: - QRCodeViewControllerDelegate
extension BrowserViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        guard let tab = tabManager.selectedTab else { return }
        
        // Open the scanned URL in the current tab
        finishEditingAndSubmit(url, visitType: .typed, forTab: tab)
        
        // Log the QR code scan
        DefaultLogger.shared.log("QR code scanned with URL: \(url)",
                                level: .info,
                                category: .tabs)
    }
    
    func didScanQRCodeWithTextContent(_ content: TextContentDetector.DetectedType?, rawText: String) {
        // Handle text content from QR code (e.g., plain text, phone numbers, etc.)
        guard let tab = tabManager.selectedTab else { return }
        
        // For now, treat text content as a search query
        submitSearchText(rawText, forTab: tab)
        
        DefaultLogger.shared.log("QR code scanned with text: \(rawText)",
                                level: .info,
                                category: .tabs)
    }
    
    var qrCodeScanningPermissionLevel: QRCodeScanPermissions {
        // Use default behavior - prompt user before opening URLs
        return .default
    }
}
