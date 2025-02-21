// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import WebKit

protocol BrowserNavigationHandler: AnyObject, QRCodeNavigationHandler {
    /// Asks to show a settings page, can be a general settings page or a child page
    /// - Parameter settings: The settings route we're trying to get to
    func show(settings: Route.SettingsSection)

    /// Asks to show a enhancedTrackingProtection page, can be a general enhancedTrackingProtection page or a child page
    func showEnhancedTrackingProtection(sourceView: UIView)

    /// Shows the specified section of the home panel.
    ///
    /// - Parameter homepanelSection: The section to be displayed.
    func show(homepanelSection: Route.HomepanelSection)

    /// Shows the share extension.
    ///
    /// - Parameter url: The url to be shared.
    /// - Parameter sourceView: The reference view to show the popoverViewController.
    /// - Parameter sourceRect: An optional rect to use for ipad popover presentation
    /// - Parameter toastContainer: The view in which is displayed the toast results from actions in the share extension.
    /// - Parameter popoverArrowDirection: The arrow direction for the view controller presented as popover.
    func showShareExtension(url: URL,
                            sourceView: UIView,
                            sourceRect: CGRect?,
                            toastContainer: UIView,
                            popoverArrowDirection: UIPopoverArrowDirection)

    /// Initiates the modal presentation of the Fakespot flow for analyzing the authenticity of a product's reviews.
    /// - Parameter productURL: The URL of the product for which the reviews will be analyzed.
    func showFakespotFlowAsModal(productURL: URL)

    /// Initiates the sidebar presentation of the Fakespot flow for analyzing the authenticity of a product's reviews.
    /// - Parameter productURL: The URL of the product for which the reviews will be analyzed.
    /// - Parameter sidebarContainer: The view that will contain the sidebar.
    /// - Parameter parentViewController: The view controller that the Fakespot flow will be a child of.
    func showFakespotFlowAsSidebar(productURL: URL,
                                   sidebarContainer: SidebarEnabledViewProtocol,
                                   parentViewController: UIViewController)

    /// Initiates the modal dismissal of the Fakespot flow for analyzing the authenticity of a product's reviews.
    /// - Parameter animated: Determines whether the modal is dismissed with animation or not.
    func dismissFakespotModal(animated: Bool)

    /// Initiates the sidebar dismissal of the Fakespot flow for analyzing the authenticity of a product's reviews.
    /// - Parameter sidebarContainer: The view that contains the sidebar.
    /// - Parameter parentViewController: The view controller that the Fakespot flow is a child of.
    func dismissFakespotSidebar(sidebarContainer: SidebarEnabledViewProtocol, parentViewController: UIViewController)

    /// Initiates the update of the Fakespot sidebar for analyzing the authenticity of a product's reviews.
    /// - Parameter productURL: The URL of the product for which the reviews will be analyzed. 
    /// - Parameter sidebarContainer: The view that contains the sidebar.
    /// - Parameter parentViewController: The view controller that the Fakespot flow is a child of.
    func updateFakespotSidebar(productURL: URL,
                               sidebarContainer: SidebarEnabledViewProtocol,
                               parentViewController: UIViewController)

    /// Shows a CreditCardAutofill view to select credit cards in order to autofill cards forms.
    func showCreditCardAutofill(creditCard: CreditCard?,
                                decryptedCard: UnencryptedCreditCardFields?,
                                viewType state: CreditCardBottomSheetState,
                                frame: WKFrameInfo?,
                                alertContainer: UIView)

    /// Shows authentication view controller to authorize access to sensitive data.
    func showRequiredPassCode()

    /// Shows the Tab Tray View Controller.
    func showTabTray(selectedPanel: TabTrayPanelType)
}

extension BrowserNavigationHandler {
    func showShareExtension(url: URL, sourceView: UIView, sourceRect: CGRect? = nil, toastContainer: UIView, popoverArrowDirection: UIPopoverArrowDirection = .up) {
        showShareExtension(url: url, sourceView: sourceView, sourceRect: sourceRect, toastContainer: toastContainer, popoverArrowDirection: popoverArrowDirection)
    }
}
