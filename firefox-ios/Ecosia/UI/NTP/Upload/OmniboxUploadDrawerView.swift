// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

@available(iOS 16.0, *)
private enum OmniboxUploadDrawerUX {
    static let sheetHeight: CGFloat = 156
}

/// Upload source picker presented as a sheet, matching `EcosiaAccountImpactView` presentation.
@available(iOS 16.0, *)
public struct OmniboxUploadDrawerSheet: View {
    private let windowUUID: WindowUUID
    private let onSelect: (OmniboxUploadOption) -> Void

    public init(windowUUID: WindowUUID, onSelect: @escaping (OmniboxUploadOption) -> Void) {
        self.windowUUID = windowUUID
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { geometry in
            OmniboxUploadDrawerView(windowUUID: windowUUID, onSelect: onSelect)
                .padding(.horizontal, .ecosia.space._m)
                .presentationDetents([.height(OmniboxUploadDrawerUX.sheetHeight - geometry.safeAreaInsets.bottom)])
                .presentationDragIndicator(.visible)
        }
    }
}

@available(iOS 16.0, *)
struct OmniboxUploadDrawerView: View {
    private enum UX {
        static let iconContainerHeight: CGFloat = 56
        static let iconSize: CGFloat = 20
    }

    private let windowUUID: WindowUUID
    private let onSelect: (OmniboxUploadOption) -> Void

    @State private var theme = OmniboxUploadDrawerViewTheme()

    init(windowUUID: WindowUUID, onSelect: @escaping (OmniboxUploadOption) -> Void) {
        self.windowUUID = windowUUID
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .center, spacing: .ecosia.space._m) {
            ForEach(OmniboxUploadOption.allCases, id: \.self) { option in
                uploadOptionButton(for: option)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .frame(height: OmniboxUploadDrawerUX.sheetHeight)
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String.localized(.uploadDrawerAccessibilityLabel))
        .ecosiaThemed(windowUUID, $theme)
        .presentationBackgroundIfAvailable(theme.backgroundColor)
    }

    private func uploadOptionButton(for option: OmniboxUploadOption) -> some View {
        Button {
            onSelect(option)
        } label: {
            VStack(spacing: .ecosia.space._1s) {
                Image.ecosia(option.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(theme.iconTintColor)
                    .frame(width: UX.iconSize, height: UX.iconSize)
                    .frame(maxWidth: .infinity)
                    .frame(height: UX.iconContainerHeight)
                    .background(
                        RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                            .fill(theme.iconBackgroundColor)
                    )

                Text(option.title)
                    .font(.caption)
                    .foregroundColor(theme.labelColor)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityHint(option.accessibilityHint)
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }
}

@available(iOS 16.0, *)
struct OmniboxUploadDrawerViewTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var iconBackgroundColor = Color.white
    var iconTintColor = Color.black
    var labelColor = Color.gray

    mutating func applyTheme(theme: Theme) {
        let colors = theme.colors.ecosia
        backgroundColor = Color(colors.backgroundPrimaryDecorative)
        iconBackgroundColor = Color(colors.backgroundElevation1)
        iconTintColor = Color(colors.buttonContentSecondary)
        labelColor = Color(colors.textSecondary)
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
