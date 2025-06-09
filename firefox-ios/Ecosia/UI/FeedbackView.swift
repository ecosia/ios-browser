// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// FeedbackType represents the type of feedback a user can submit
enum FeedbackType: String, CaseIterable, Identifiable {
    case reportIssue = "Report an issue"
    case generalQuestion = "General question"
    case suggestionOrFeedback = "Suggestion or feedback"

    var id: String { self.rawValue }
    
    var analyticsIdentfier: String {
        switch self {
        case .reportIssue:
            return "report_issue"
        case .generalQuestion:
            return "general_question"
        case .suggestionOrFeedback:
            return "suggestion_or_feedback"
        }
    }

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
    // User input state
    @State private var selectedFeedbackType: FeedbackType?
    @State private var feedbackText: String = ""
    @State private var isButtonEnabled: Bool = false

    // Theme handling
    @StateObject private var viewModel = FeedbackViewModel()
    let windowUUID: WindowUUID?

    // Define a dismiss callback that will be injected by the hosting controller
    var onDismiss: (() -> Void)?

    // Layout constants
    private struct Layout {
        static let cornerRadius: CGFloat = .ecosia.borderRadius._l
        static let buttonCornerRadius: CGFloat = 25
        static let textEditorHeight: CGFloat = 100
    }

    public init(windowUUID: WindowUUID? = nil,
                initialTheme: Theme? = nil) {
        self.windowUUID = windowUUID

        // Apply initial theme if provided
        if let theme = initialTheme {
            _viewModel = StateObject(wrappedValue: FeedbackViewModel(theme: theme))
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                // Background color - using ntpBackground like in MarketsController
                viewModel.ntpBackgroundColor.ignoresSafeArea()

                FeedbackContentView(
                    viewModel: viewModel,
                    selectedFeedbackType: $selectedFeedbackType,
                    feedbackText: $feedbackText,
                    isButtonEnabled: $isButtonEnabled,
                    updateButtonState: updateButtonState,
                    sendFeedback: sendFeedback
                )
                .navigationTitle(String.localized(.sendFeedback))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(String.localized(.close)) {
                            dismiss()
                        }
                        .foregroundColor(viewModel.brandPrimaryColor)
                        .accessibilityIdentifier("close_feedback_button")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                let themeManager = AppContainer.shared.resolve() as ThemeManager
                viewModel.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
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
        let idiom = UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        let browserVersion = "Ecosia \(idiom) \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

        // Send the feedback using the navigation method with the collected data
        Analytics.shared.navigation(.click, label: .sendFeedback, options: [
            "feedback_type": selectedFeedbackType?.analyticsIdentfier ?? "",
            "device_type": deviceType,
            "os": operatingSystem,
            "browser_version": browserVersion,
            "feedback_text": feedbackText
        ])

        // Dismiss the view
        dismiss()
    }
}

// Break down content into separate view to avoid SwiftUI type-checking time limitation
private struct FeedbackContentView: View {
    let viewModel: FeedbackViewModel
    @Binding var selectedFeedbackType: FeedbackType?
    @Binding var feedbackText: String
    @Binding var isButtonEnabled: Bool
    let updateButtonState: () -> Void
    let sendFeedback: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._1l) {
            // Header section
            Text(String.localized(.whatWouldYouLikeToShare))
                .font(.title3)
                .foregroundColor(viewModel.textPrimaryColor)
                .padding(.horizontal, .ecosia.space._m)
                .padding(.top, .ecosia.space._m)
                .accessibilityIdentifier("feedback_title")

            // Feedback type selection section
            FeedbackTypeSection(
                viewModel: viewModel,
                selectedFeedbackType: $selectedFeedbackType,
                updateButtonState: updateButtonState
            )

            // Feedback text and send button wrapped in a VStack with 16pt spacing
            VStack(spacing: .ecosia.space._m) {
                // Feedback text input section
                FeedbackTextSection(
                    viewModel: viewModel,
                    feedbackText: $feedbackText,
                    updateButtonState: updateButtonState
                )

                // Send button container
                SendButtonSection(
                    viewModel: viewModel,
                    isButtonEnabled: isButtonEnabled,
                    sendFeedback: sendFeedback
                )
            }
            .padding(.horizontal, .ecosia.space._m)
            Spacer()
        }
        .background(viewModel.ntpBackgroundColor)
    }
}

private struct FeedbackTypeSection: View {
    let viewModel: FeedbackViewModel
    @Binding var selectedFeedbackType: FeedbackType?
    let updateButtonState: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ForEach(FeedbackType.allCases) { type in
                    Button(action: {
                        selectedFeedbackType = type
                        updateButtonState()
                    }) {
                        HStack {
                            Text(type.localizedString)
                                .font(.body)
                                .foregroundColor(viewModel.textPrimaryColor)

                            Spacer()

                            if selectedFeedbackType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(viewModel.brandPrimaryColor)
                                    .accessibility(label: Text("Selected"))
                            }
                        }
                        .padding(.ecosia.space._m)
                        .background(viewModel.barBackgroundColor)
                    }

                    if type != FeedbackType.allCases.last {
                        Divider()
                            .padding(.leading, .ecosia.space._m)
                    }
                }
            }
            .frame(minHeight: 44 * CGFloat(FeedbackType.allCases.count))
        }
        .background(viewModel.barBackgroundColor)
        .cornerRadius(.ecosia.borderRadius._l)
        .overlay(
            RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                .stroke(viewModel.borderColor, lineWidth: 1)
        )
        .padding(.horizontal, .ecosia.space._m)
    }
}

private struct FeedbackTextSection: View {
    let viewModel: FeedbackViewModel
    @Binding var feedbackText: String
    let updateButtonState: () -> Void

    var body: some View {
        VStack {
            TextEditor(text: $feedbackText)
                .frame(height: 100)
                .font(.body)
                .foregroundColor(viewModel.textPrimaryColor)
                .padding(.ecosia.space._s)
                .background(viewModel.barBackgroundColor)
                .cornerRadius(.ecosia.borderRadius._l)
                .overlay(
                    ZStack {
                        if feedbackText.isEmpty {
                            HStack {
                                Text(String.localized(.addMoreDetailAboutYourFeedback))
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.textSecondaryColor)
                                    .padding(.horizontal, .ecosia.space._s)
                                    .padding(.top, .ecosia.space._s)
                                    .allowsHitTesting(false)
                                Spacer()
                            }
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                        .stroke(viewModel.borderColor, lineWidth: 1)
                )
                .onChange(of: feedbackText) { _ in
                    updateButtonState()
                }
        }
        .background(viewModel.barBackgroundColor)
        .cornerRadius(.ecosia.borderRadius._l)
    }
}

private struct SendButtonSection: View {
    let viewModel: FeedbackViewModel
    let isButtonEnabled: Bool
    let sendFeedback: () -> Void

    var body: some View {
        VStack {
            Button(action: sendFeedback) {
                Text(String.localized(.send))
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.ecosia.space._m)
                    .foregroundColor(.white)
                    .background(isButtonEnabled ? viewModel.buttonColor : Color(UIColor.systemGray4))
                    .cornerRadius(.ecosia.borderRadius._1l)
            }
            .disabled(!isButtonEnabled)
        }
        .background(viewModel.barBackgroundColor)
        .cornerRadius(.ecosia.borderRadius._l)
        .overlay(
            RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                .stroke(viewModel.borderColor, lineWidth: 1)
        )
        .padding(.bottom, .ecosia.space._m)
        .accessibilityIdentifier("send_feedback_button")
    }
}

/// View model to handle theming for the FeedbackView
class FeedbackViewModel: ObservableObject {
    @Published var backgroundColor = Color.white
    @Published var ntpBackgroundColor = Color.white
    @Published var barBackgroundColor = Color.white
    @Published var stepsBackgroundColor = Color(UIColor.secondarySystemGroupedBackground)
    @Published var cellBackgroundColor = Color(UIColor.systemBackground)
    @Published var tableViewRowTextColor = Color.black
    @Published var textPrimaryColor = Color.black
    @Published var textSecondaryColor = Color.gray
    @Published var buttonColor = Color.blue
    @Published var brandPrimaryColor = Color.blue
    @Published var borderColor = Color.gray.opacity(0.2)

    init(theme: Theme? = nil) {
        if let theme = theme {
            applyTheme(theme: theme)
        }
    }

    func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
        ntpBackgroundColor = Color(theme.colors.ecosia.ntpBackground)
        barBackgroundColor = Color(theme.colors.ecosia.barBackground)
        stepsBackgroundColor = Color(theme.colors.ecosia.backgroundSecondary)
        cellBackgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
        tableViewRowTextColor = Color(theme.colors.ecosia.tableViewRowText)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        buttonColor = Color(theme.colors.ecosia.buttonBackgroundPrimaryActive)
        brandPrimaryColor = Color(theme.colors.ecosia.brandPrimary)
        borderColor = Color.border
    }
}

/// UIKit wrapper for the SwiftUI FeedbackView
public class FeedbackViewController: UIHostingController<FeedbackView> {
    public init(windowUUID: WindowUUID? = nil) {
        // Get the current theme from the theme manager
        let themeManager = AppContainer.shared.resolve() as ThemeManager
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        // Create the FeedbackView with the current theme
        var feedbackView = FeedbackView(windowUUID: windowUUID, initialTheme: theme)

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
