// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

@available(iOS 16.0, *)
private enum OmniboxUploadDrawerUX {
    static let shortcutTileSize: CGFloat = 56
    static let shortcutTileCornerRadius: CGFloat = 16
    static let shortcutWidth: CGFloat = 72
    static let iconSize: CGFloat = 20
    static let chatModeRowMinHeight: CGFloat = 68
    static let doneButtonSize: CGFloat = 44
    static let doneGlyphSize: CGFloat = 17
    static let sparkleSize: CGFloat = 16
    static let footerHeight: CGFloat = 44
    static let footerCornerRadius: CGFloat = 16
    static let signInIconWidth: CGFloat = 18
}

/// The omnibox "AI tools" drawer presented as a sheet, matching
/// `EcosiaAccountImpactView` presentation. Hosts the upload sources (Camera,
/// Photos, Files) plus the AI Chat modes list.
@available(iOS 16.0, *)
public struct OmniboxUploadDrawerSheet: View {
    private let windowUUID: WindowUUID
    private let provider: SearchProvider
    private let selectedChatMode: OmniboxChatMode?
    private let isAuthenticated: Bool
    private let hasOptedOutOfChatThreads: Bool
    private let onSelect: (OmniboxUploadOption) -> Void
    private let onSelectChatMode: (OmniboxChatMode) -> Void
    private let onLogin: () -> Void

    public init(windowUUID: WindowUUID,
                provider: SearchProvider,
                selectedChatMode: OmniboxChatMode?,
                isAuthenticated: Bool,
                hasOptedOutOfChatThreads: Bool = false,
                onSelect: @escaping (OmniboxUploadOption) -> Void,
                onSelectChatMode: @escaping (OmniboxChatMode) -> Void,
                onLogin: @escaping () -> Void) {
        self.windowUUID = windowUUID
        self.provider = provider
        self.selectedChatMode = selectedChatMode
        self.isAuthenticated = isAuthenticated
        self.hasOptedOutOfChatThreads = hasOptedOutOfChatThreads
        self.onSelect = onSelect
        self.onSelectChatMode = onSelectChatMode
        self.onLogin = onLogin
    }

    public var body: some View {
        OmniboxUploadDrawerView(windowUUID: windowUUID,
                                provider: provider,
                                selectedChatMode: selectedChatMode,
                                isAuthenticated: isAuthenticated,
                                hasOptedOutOfChatThreads: hasOptedOutOfChatThreads,
                                onSelect: onSelect,
                                onSelectChatMode: onSelectChatMode,
                                onLogin: onLogin)
    }
}

@available(iOS 16.0, *)
struct OmniboxUploadDrawerView: View {
    private typealias UX = OmniboxUploadDrawerUX

    private let windowUUID: WindowUUID
    private let provider: SearchProvider
    private let selectedChatMode: OmniboxChatMode?
    private let isAuthenticated: Bool
    private let hasOptedOutOfChatThreads: Bool
    private let onSelect: (OmniboxUploadOption) -> Void
    private let onSelectChatMode: (OmniboxChatMode) -> Void
    private let onLogin: () -> Void

    // `Environment` is qualified because the Ecosia framework defines its own
    // `Environment` type, which otherwise shadows the SwiftUI property wrapper.
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var theme = OmniboxUploadDrawerViewTheme()

    init(windowUUID: WindowUUID,
         provider: SearchProvider,
         selectedChatMode: OmniboxChatMode?,
         isAuthenticated: Bool,
         hasOptedOutOfChatThreads: Bool = false,
         onSelect: @escaping (OmniboxUploadOption) -> Void,
         onSelectChatMode: @escaping (OmniboxChatMode) -> Void,
         onLogin: @escaping () -> Void) {
        self.windowUUID = windowUUID
        self.provider = provider
        self.selectedChatMode = selectedChatMode
        self.isAuthenticated = isAuthenticated
        self.hasOptedOutOfChatThreads = hasOptedOutOfChatThreads
        self.onSelect = onSelect
        self.onSelectChatMode = onSelectChatMode
        self.onLogin = onLogin
    }

    /// Only Ecosia's AI runs on an Ecosia account, so only its rows are gated on
    /// sign-in and only it offers the in-app upload sources.
    private var isEcosiaProvider: Bool { provider == .ecosia }

    private var availableModes: [OmniboxChatMode] { OmniboxChatMode.modes(for: provider) }

    /// In-app Camera/Photos/Files only apply when the drawer is for Ecosia (same as NTP `usesEcosiaAIBackend`).
    private var usesEcosiaAIBackend: Bool { provider == .ecosia }

    private var isUploadEnabled: Bool {
        OmniboxFileUploadAvailability.areSourcesEnabled(
            usesEcosiaAIBackend: usesEcosiaAIBackend,
            isAuthenticated: isAuthenticated,
            hasOptedOutOfChatThreads: hasOptedOutOfChatThreads
        )
    }

    /// A chat mode is selectable only when the user is signed in; signed-out
    /// users may pick Standard AI Chat (no advanced features) but every other
    /// mode is shown disabled.
    private func isModeEnabled(_ mode: OmniboxChatMode) -> Bool {
        guard isEcosiaProvider else { return true }
        return isAuthenticated || mode == .standard
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: .ecosia.space._l) {
                // The "AI tools" title + checkmark and the modes list are Chat
                // Modes UI; the upload shortcuts stay under the File Upload flag.
                if ChatModesFeatureFlag.isEnabled {
                    header
                }
                VStack(spacing: 0) {
                    uploadRow
                    if ChatModesFeatureFlag.isEnabled {
                        chatModeList
                    }
                }
            }
            if ChatModesFeatureFlag.isEnabled, isEcosiaProvider {
                footer
                    .padding(.top, .ecosia.space._m)
            }
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.top, .ecosia.space._2l)
        .padding(.bottom, .ecosia.space._2l)
        .frame(maxWidth: .infinity)
        .dynamicHeightPresentationDetent(padding: 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String.localized(.aiToolsTitle))
        .ecosiaThemed(windowUUID, $theme)
        .presentationDragIndicator(.visible)
        .presentationBackgroundIfAvailable(theme.backgroundColor)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(String.localized(.aiToolsTitle))
                // Headline text style is 17pt; semibold matches the design's
                // 590 weight (the closest named system-font weight).
                .font(.headline.weight(.semibold))
                .foregroundColor(theme.titleColor)

            HStack {
                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    doneButtonBackground(
                        Image(systemName: "checkmark")
                            .font(.system(size: UX.doneGlyphSize, weight: .medium))
                            .foregroundColor(theme.iconTintColor)
                            .frame(width: UX.doneButtonSize, height: UX.doneButtonSize)
                    )
                }
                .accessibilityLabel(String.localized(.done))
                .accessibilityHint(String.localized(.aiToolsDoneAccessibilityHint))
                .accessibilityIdentifier("OmniboxAIToolsDoneButton")
            }
        }
    }

    @ViewBuilder
    private func doneButtonBackground(_ glyph: some View) -> some View {
        if #available(iOS 26, *) {
            glyph.glassEffect(.regular.interactive(), in: Circle())
        } else {
            glyph.background(Circle().fill(theme.doneBackgroundColor))
        }
    }

    // MARK: - Upload sources

    private var uploadRow: some View {
        HStack(alignment: .top, spacing: .ecosia.space._1s) {
            ForEach(OmniboxUploadOption.allCases, id: \.self) { option in
                uploadOptionButton(for: option)
            }
        }
        .padding(.vertical, .ecosia.space._1s)
    }

    private func uploadOptionButton(for option: OmniboxUploadOption) -> some View {
        let contentColor = isUploadEnabled ? theme.iconTintColor : theme.disabledColor
        return Button {
            onSelect(option)
        } label: {
            VStack(spacing: .ecosia.space._1s) {
                Image.ecosia(option.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(contentColor)
                    .frame(width: UX.iconSize, height: UX.iconSize)
                    .frame(width: UX.shortcutTileSize, height: UX.shortcutTileSize)
                    .background(
                        RoundedRectangle(cornerRadius: UX.shortcutTileCornerRadius)
                            .fill(theme.iconBackgroundColor)
                    )

                Text(option.title)
                    .font(.footnote)
                    .foregroundColor(isUploadEnabled ? theme.labelColor : theme.disabledColor)
                    .multilineTextAlignment(.center)
            }
            .frame(width: UX.shortcutWidth)
            .frame(maxWidth: .infinity)
        }
        // Ecosia uploads require an account and chat-thread history, so the media
        // pickers are disabled for signed-out users and for users who opted out of
        // chat threads. Other providers redirect to their own site, which needs no
        // Ecosia account.
        .disabled(!isUploadEnabled)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityHint(option.accessibilityHint)
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    // MARK: - Chat modes

    private var chatModeList: some View {
        VStack(spacing: 0) {
            ForEach(Array(availableModes.enumerated()), id: \.element) { index, mode in
                chatModeRow(for: mode, showsSeparator: index < availableModes.count - 1)
            }
        }
        .background(theme.listBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: .ecosia.borderRadius._1l))
    }

    private func chatModeRow(for mode: OmniboxChatMode, showsSeparator: Bool) -> some View {
        let isEnabled = isModeEnabled(mode)
        let isSelected = mode == selectedChatMode
        return Button {
            onSelectChatMode(mode)
        } label: {
            HStack(spacing: .ecosia.space._1s) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(mode.title)
                        .font(.body)
                        .foregroundColor(isEnabled ? theme.titleColor : theme.disabledColor)
                    Text(mode.subtitle)
                        .font(.footnote)
                        .foregroundColor(isEnabled ? theme.subtitleColor : theme.disabledColor)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                chatModeRowAccessory(for: mode, isEnabled: isEnabled, isSelected: isSelected)
                    .frame(width: UX.iconSize, height: UX.iconSize)
            }
            .padding(.vertical, .ecosia.space._1s)
            .frame(minHeight: UX.chatModeRowMinHeight)
            .overlay(alignment: .bottom) {
                if showsSeparator {
                    Rectangle()
                        .fill(theme.dividerColor)
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, .ecosia.space._m)
            .contentShape(Rectangle())
        }
        .buttonStyle(ChatModeRowButtonStyle(highlightColor: theme.rowHighlightColor))
        // Signed-out users can only pick Standard; other modes stay visible but
        // non-interactive until they sign in.
        .disabled(!isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mode.accessibilityLabel)
        .accessibilityHint(mode.accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier(mode.accessibilityIdentifier)
    }

    /// The selected mode swaps its icon for a checkmark; re-tapping it only closes
    /// the drawer, since deselection happens from the omnibox chip.
    @ViewBuilder
    private func chatModeRowAccessory(for mode: OmniboxChatMode, isEnabled: Bool, isSelected: Bool) -> some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: UX.doneGlyphSize, weight: .medium))
                .foregroundColor(theme.selectedCheckmarkColor)
                .accessibilityHidden(true)
        } else {
            Image.ecosia(mode.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(isEnabled ? theme.rowIconColor : theme.disabledColor)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Footer

    /// Signed-in users get the "redirect to AI Chat" notice; signed-out users
    /// get a sign-in disclaimer with a CTA that unlocks the advanced modes.
    @ViewBuilder
    private var footer: some View {
        if isAuthenticated {
            redirectNoticeFooter
        } else {
            signInFooter
        }
    }

    private var redirectNoticeFooter: some View {
        HStack(spacing: .ecosia.space._1s) {
            Text(String.localized(.aiToolsRedirectNotice))
                .font(.footnote)
                .foregroundColor(theme.subtitleColor)
            Spacer(minLength: 0)
            Image.ecosia("ai-sparkle")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(theme.iconTintColor)
                .frame(width: UX.sparkleSize, height: UX.sparkleSize)
        }
        .padding(.horizontal, .ecosia.space._m)
        .frame(height: UX.footerHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: UX.footerCornerRadius)
                .fill(theme.footerBackgroundColor)
        )
        .accessibilityElement(children: .combine)
    }

    private var signInFooter: some View {
        HStack(alignment: .center, spacing: .ecosia.space._m) {
            Text(String.localized(.chatModesSignInDisclaimer))
                .font(.footnote)
                .foregroundColor(theme.titleColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, .ecosia.space._1s)
            Spacer(minLength: 0)
            signInButton
        }
        .frame(maxWidth: .infinity)
    }

    private var signInButton: some View {
        Button {
            onLogin()
        } label: {
            HStack(spacing: .ecosia.space._1s) {
                Image.ecosia("sign-in")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UX.signInIconWidth)
                Text(String.localized(.signIn))
                    .font(.system(size: .ecosia.font._m, weight: .semibold))
            }
            .foregroundColor(theme.signInButtonTextColor)
            .padding(.horizontal, .ecosia.space._m)
            .frame(height: UX.footerHeight)
            .background(Capsule().fill(theme.signInButtonBackgroundColor))
        }
        .accessibilityLabel(String.localized(.signIn))
        .accessibilityIdentifier("OmniboxAIToolsSignInButton")
    }
}

@available(iOS 16.0, *)
struct OmniboxUploadDrawerViewTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var iconBackgroundColor = Color.white
    var iconTintColor = Color.black
    var labelColor = Color.gray
    var titleColor = Color.black
    var subtitleColor = Color.gray
    var rowIconColor = Color.gray
    var disabledColor = Color.gray
    var rowHighlightColor = Color.gray.opacity(0.2)
    var dividerColor = Color.gray.opacity(0.2)
    var footerBackgroundColor = Color.white
    var doneBackgroundColor = Color.gray.opacity(0.2)
    var listBackgroundColor = Color.white
    var selectedCheckmarkColor = Color.green
    var signInButtonBackgroundColor = Color.green
    var signInButtonTextColor = Color.black

    mutating func applyTheme(theme: Theme) {
        let colors = theme.colors.ecosia
        backgroundColor = Color(colors.backgroundPrimaryDecorative)
        iconBackgroundColor = Color(colors.backgroundElevation1)
        iconTintColor = Color(colors.buttonContentSecondary)
        labelColor = Color(colors.textPrimary)
        titleColor = Color(colors.textPrimary)
        subtitleColor = Color(colors.textSecondary)
        rowIconColor = Color(colors.iconDecorative)
        disabledColor = Color(colors.stateDisabled)
        rowHighlightColor = Color(colors.buttonBackgroundTransparentActive)
        dividerColor = Color(colors.borderDecorative)
        footerBackgroundColor = Color(colors.backgroundTertiary)
        doneBackgroundColor = Color(colors.buttonBackgroundTransparentActive)
        listBackgroundColor = Color(colors.backgroundElevation1)
        selectedCheckmarkColor = Color(colors.brandPrimary)
        // Sign-in CTA uses the same featured grellow pill as the design-system primary button.
        signInButtonBackgroundColor = Color(colors.buttonBackgroundFeatured)
        signInButtonTextColor = Color(colors.textStaticDark)
    }
}

/// Gives chat-mode rows the pressed highlight of a native list cell.
@available(iOS 16.0, *)
private struct ChatModeRowButtonStyle: ButtonStyle {
    let highlightColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? highlightColor : .clear)
    }
}

// MARK: - Conditional presentation background

@available(iOS 16.0, *)
private extension View {
    @ViewBuilder
    func presentationBackgroundIfAvailable(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(color)
        } else {
            self
        }
    }
}
