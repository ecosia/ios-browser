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
    // Callback for notifying when feedback was submitted
    var onFeedbackSubmitted: (() -> Void)?

    // Layout constants
    struct UX {
        static let cornerRadius: CGFloat = .ecosia.borderRadius._l
        static let buttonCornerRadius: CGFloat = 25
        static let textEditorHeight: CGFloat = 200
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

                viewModel.backgroundColor.ignoresSafeArea()

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
        let browserVersion = "Ecosia \(idiom) \(Bundle.version)"

        // Send the feedback using the navigation method with the collected data
        Analytics.shared.sendFeedback([
            "feedback_type": selectedFeedbackType?.analyticsIdentfier ?? "",
            "device_type": deviceType,
            "os": operatingSystem,
            "browser_version": browserVersion,
            "feedback_text": feedbackText
        ])

        // Notify that feedback was submitted
        onFeedbackSubmitted?()

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

            // Combined container for text input and send button
            VStack(spacing: .ecosia.space._m) {
                // Feedback text input section with proper placeholder
                ZStack(alignment: .topLeading) {

                    viewModel.backgroundColor

                    TextEditor(text: $feedbackText)
                        .font(.body)
                        .transparentScrolling()
                        .foregroundColor(viewModel.textPrimaryColor)
                        .padding(.horizontal, .ecosia.space._s)
                        .padding(.vertical, .ecosia.space._m)
                        .border(viewModel.borderColor, width: viewModel.borderWidth)
                        .onChange(of: feedbackText) { _ in
                            updateButtonState()
                        }

                    if feedbackText.isEmpty {
                        Text(String.localized(.addMoreDetailAboutYourFeedback))
                            .font(.body)
                            .foregroundColor(viewModel.textSecondaryColor)
                            .padding(.horizontal, .ecosia.space._m)
                            .padding(.vertical, .ecosia.space._1l)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: FeedbackView.UX.textEditorHeight)
                .cornerRadius(.ecosia.borderRadius._l)
                .padding(.top, .ecosia.space._m)
                .padding(.horizontal, .ecosia.space._m)

                // Send button
                Button(action: sendFeedback) {
                    Text(String.localized(.send))
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.ecosia.space._m)
                        .foregroundColor(.white)
                        .background(isButtonEnabled ? viewModel.buttonBackgroundColor : viewModel.buttonDisabledBackgroundColor)
                        .cornerRadius(.ecosia.borderRadius._m)
                }
                .disabled(!isButtonEnabled)
                .clipShape(Capsule())
                .padding(.horizontal, .ecosia.space._m)
                .padding(.bottom, .ecosia.space._m)
                .accessibilityIdentifier("feedback_cta_button")
                .accessibilityLabel(Text("Send feedback"))
                .accessibilityAddTraits(.isButton)
            }
            .background(viewModel.sectionBackgroundColor)
            .cornerRadius(.ecosia.borderRadius._l)
            .padding(.horizontal, .ecosia.space._m)

            Spacer()
        }
        .background(viewModel.backgroundColor)
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
                        .background(viewModel.sectionBackgroundColor)
                    }

                    if type != FeedbackType.allCases.last {
                        Divider()
                            .padding(.leading, .ecosia.space._m)
                    }
                }
            }
            .frame(minHeight: 44 * CGFloat(FeedbackType.allCases.count))
        }
        .background(viewModel.sectionBackgroundColor)
        .cornerRadius(.ecosia.borderRadius._l)
        .padding(.horizontal, .ecosia.space._m)
    }
}

/// View model to handle theming for the FeedbackView
class FeedbackViewModel: ObservableObject {
    @Published var backgroundColor = Color.white
    @Published var sectionBackgroundColor = Color.white
    @Published var feedbackTypeListItemBackgroundColor = Color(UIColor.systemBackground)
    @Published var textPrimaryColor = Color.black
    @Published var textSecondaryColor = Color.gray
    @Published var buttonBackgroundColor = Color.blue
    @Published var buttonDisabledBackgroundColor = Color.gray
    @Published var brandPrimaryColor = Color.blue
    @Published var borderColor = Color.gray.opacity(0.2)
    @Published var borderWidth: CGFloat = 1

    init(theme: Theme? = nil) {
        if let theme = theme {
            applyTheme(theme: theme)
        }
    }

    func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.ntpBackground)
        sectionBackgroundColor = Color(theme.colors.ecosia.barBackground)
        feedbackTypeListItemBackgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        buttonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundPrimaryActive)
        buttonDisabledBackgroundColor = Color(theme.colors.ecosia.stateDisabled)
        brandPrimaryColor = Color(theme.colors.ecosia.brandPrimary)
        borderColor = Color(theme.colors.ecosia.borderDecorative)
    }
}

/// UIKit wrapper for the SwiftUI FeedbackView
public class FeedbackViewController: UIHostingController<FeedbackView> {
    /// Completion handler to be called when feedback is submitted
    public var onFeedbackSubmitted: (() -> Void)?

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

        // Add callback for feedback submission
        feedbackView.onFeedbackSubmitted = { [weak self] in
            self?.onFeedbackSubmitted?()
        }

        // Update the rootView with the complete FeedbackView
        self.rootView = feedbackView
        self.modalPresentationStyle = .formSheet
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    FeedbackView(windowUUID: UUID())
}
