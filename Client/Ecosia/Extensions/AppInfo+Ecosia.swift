// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

extension AppInfo {
    
    public static var installReceipt: String? {
        
        let receiptURL = Bundle.main.appStoreReceiptURL
        
        if let receiptURL = receiptURL, let receiptData = try? Data(contentsOf: receiptURL) {
            return receiptData.base64EncodedString(options: [])
            
        }
        
        return nil
    }
}
