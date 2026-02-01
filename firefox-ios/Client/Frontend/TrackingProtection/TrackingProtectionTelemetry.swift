// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Glean

struct TrackingProtectionTelemetry {
    func showClearCookiesAlert() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.showClearCookiesAlert.record()
    }

    func clearCookiesAndSiteData() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.tappedClearCookies.record()
    }

    func showTrackingProtectionDetails() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.showEtpDetails.record()
    }

    func showBlockedTrackersDetails() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.showEtpBlockedTrackersDetails.record()
    }

    func tappedShowSettings() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.showEtpSettings.record()
    }

    func dismissTrackingProtection() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.dismissEtpPanel.record()
    }

    func trackShowCertificates() {
        // Ecosia: Telemetry metrics removed in Firefox 147.2
        // GleanMetrics.TrackingProtection.showCertificates.record()
    }
}
