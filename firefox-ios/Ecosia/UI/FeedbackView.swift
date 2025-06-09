// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit

/// FeedbackType represents the type of feedback a user can submit
enum FeedbackType: String, CaseIterable, Identifiable {
    case reportIssue = "Report an issue"
    case generalQuestion = "General question"
    case suggestionOrFeedback = "Suggestion or feedback"

    var id: String { self.rawValue }

    var localizedString: String {
        switch self {
        case .reportIssue:
            return String.localized(.reportIssue)
        case .generalQuestion:
            return String.localized(.generalQuestion)
        case .suggestionOrFeedback:
            return String.localized(.suggestionOrFeedback)
        }
    }
}

/// The SwiftUI view for collecting user feedback
public struct FeedbackView: View {
    // Avoid using Environment property wrapper due to conflicts
    @State private var selectedFeedbackType: FeedbackType?
    @State private var feedbackText: String = ""
    @State private var isButtonEnabled: Bool = false

    // Define a dismiss callback that will be injected by the hosting controller
    var onDismiss: (() -> Void)?

    // Use Ecosia's green color
    private let ecosiaGreenColor = Color.ecosiaBundledColorWithName("Green")

    public var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                Text(String.localized(.whatWouldYouLikeToShare))
                    .font(.headline)
                    .padding(.horizontal)

                // Feedback type selection section
                VStack(spacing: 0) {
                    ForEach(FeedbackType.allCases) { type in
                        Button(action: {
                            selectedFeedbackType = type
                            updateButtonState()
                        }) {
                            HStack {
                                Text(type.localizedString)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedFeedbackType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ecosiaGreenColor)
                                }
                            }
                            .padding()
                        }
                        .background(Color(UIColor.systemBackground))

                        if type != FeedbackType.allCases.last {
                            Divider()
                                .padding(.leading)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Feedback text input section
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .overlay(
                        Group {
                            if feedbackText.isEmpty {
                                Text(String.localized(.addMoreDetailAboutYourFeedback))
                                    .foregroundColor(Color(UIColor.placeholderText))
                                    .padding(.leading, 22)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
                    .onChange(of: feedbackText) { _ in
                        updateButtonState()
                    }

                Spacer()

                // Send button
                Button(action: sendFeedback) {
                    Text(String.localized(.send))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isButtonEnabled ? ecosiaGreenColor : Color(UIColor.systemGray4))
                        .cornerRadius(25)
                }
                .disabled(!isButtonEnabled)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle(String.localized(.sendFeedback))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String.localized(.close)) {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Update the state of the send button based on user input
    private func updateButtonState() {
        isButtonEnabled = selectedFeedbackType != nil && !feedbackText.isEmpty
    }

    /// Dismiss the view
    private func dismiss() {
        onDismiss?()
    }

    /// Send the feedback to analytics and dismiss the view
    private func sendFeedback() {
        // Gather system information to include in analytics event
        let deviceType = UIDevice.current.model
        let operatingSystem = "iOS \(UIDevice.current.systemVersion)"
        let browserVersion = "Ecosia iOS \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

        // Include the feedback type in the event
        let feedbackTypeValue = selectedFeedbackType?.rawValue ?? ""

        // Log analytics event
        Analytics.shared.navigation(.click, label: .sendFeedback, options: [
            "feedback_type": feedbackTypeValue,
            "device_type": deviceType,
            "os": operatingSystem,
            "browser_version": browserVersion
        ])

        // Dismiss the view
        dismiss()
    }
}

/// UIKit wrapper for the SwiftUI FeedbackView
public class FeedbackViewController: UIHostingController<FeedbackView> {
    public init() {
        // Create the FeedbackView first without setting the dismiss callback
        var feedbackView = FeedbackView()

        // Call super.init before using self
        super.init(rootView: feedbackView)

        // Now it's safe to use self
        feedbackView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }

        // Update the rootView with the complete FeedbackView
        self.rootView = feedbackView
        self.modalPresentationStyle = .formSheet
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
