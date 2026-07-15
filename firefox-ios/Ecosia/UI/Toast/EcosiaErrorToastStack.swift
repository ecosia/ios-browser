// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct EcosiaErrorToastMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let subtitle: String
    public let title: String?

    public init(id: UUID = UUID(), title: String? = nil, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }

    public var accessibilityAnnouncement: String {
        if let title, !title.isEmpty {
            return "\(title). \(subtitle)"
        }
        return subtitle
    }
}

@MainActor
public final class EcosiaErrorToastStackModel: ObservableObject {
    @Published public var messages: [EcosiaErrorToastMessage] = []
    @Published fileprivate(set) var dismissingID: UUID?

    private enum UX {
        static let fadeDuration: TimeInterval = 0.28
        static let promoteDuration: TimeInterval = 0.35
    }

    public var onDismissCompleted: (() -> Void)?

    public init() {}

    public func append(subtitles: [String]) {
        append(messages: subtitles.map { EcosiaErrorToastMessage(subtitle: $0) })
    }

    public func append(messages newMessages: [EcosiaErrorToastMessage]) {
        guard !newMessages.isEmpty else { return }
        messages.append(contentsOf: newMessages)
    }

    public func requestDismiss(id: UUID) {
        guard dismissingID == nil,
              messages.contains(where: { $0.id == id }) else { return }

        withAnimation(.easeOut(duration: UX.fadeDuration)) {
            dismissingID = id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.fadeDuration) { [weak self] in
            guard let self else { return }
            withAnimation(.easeOut(duration: UX.promoteDuration)) {
                self.messages.removeAll { $0.id == id }
                self.dismissingID = nil
            }
            self.onDismissCompleted?()
        }
    }

    public func clear() {
        dismissingID = nil
        messages.removeAll()
    }
}

/// Overlapping top toast stack from Global Components (Figma 19211:4961).
/// Tap the stack to expand into a vertical list; tap again to collapse.
@available(iOS 16.0, *)
public struct EcosiaErrorToastStack: View {
    @ObservedObject private var model: EcosiaErrorToastStackModel
    private let windowUUID: WindowUUID
    private let onDismiss: (EcosiaErrorToastMessage) -> Void
    private let onExpandChange: (Bool) -> Void

    @State private var isVisible = false
    @State private var isExpanded = false
    @State private var frontCardHeight: CGFloat = UX.minCardHeight
    @State private var measuredExpandedHeight: CGFloat?
    @State private var dismissalLayoutHeight: CGFloat?

    private enum UX {
        static let minCardHeight: CGFloat = 56
        static let stackPeek: CGFloat = .ecosia.space._1s
        static let listSpacing: CGFloat = .ecosia.space._1s
        static let fadeDuration: TimeInterval = 0.28
        static let entranceDuration: TimeInterval = 0.45
        static let expandDuration: TimeInterval = 0.42
        static let promoteDuration: TimeInterval = 0.35
        static let maxVisibleDepth = 4
    }

    public init(
        model: EcosiaErrorToastStackModel,
        windowUUID: WindowUUID,
        onDismiss: @escaping (EcosiaErrorToastMessage) -> Void = { _ in },
        onExpandChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.model = model
        self.windowUUID = windowUUID
        self.onDismiss = onDismiss
        self.onExpandChange = onExpandChange
    }

    private var entranceAnimation: Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: UX.entranceDuration)
    }

    private var expandAnimation: Animation {
        .spring(response: UX.expandDuration, dampingFraction: 0.92)
    }

    private var promoteAnimation: Animation {
        .easeOut(duration: UX.promoteDuration)
    }

    private var layoutAnimationKey: String {
        let messageIDs = visibleMessages.map(\.id.uuidString).joined(separator: "-")
        let dismissingID = model.dismissingID?.uuidString ?? "none"
        return "\(messageIDs)-\(dismissingID)"
    }

    public var body: some View {
        if !model.messages.isEmpty {
            ZStack(alignment: .top) {
                cardMeasurementStack

                ZStack(alignment: .top) {
                    collapsedStack
                        .opacity(isExpanded ? 0 : 1)
                        .allowsHitTesting(!isExpanded)

                    expandedStack
                        .opacity(isExpanded ? 1 : 0)
                        .allowsHitTesting(isExpanded)
                }
                .frame(height: effectiveContainerHeight, alignment: .top)
                .animation(expandAnimation, value: isExpanded)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture { toggleExpanded() }
            .offset(y: isVisible ? 0 : -entranceOffset)
            .opacity(isVisible ? 1 : 0)
            .animation(entranceAnimation, value: isVisible)
            .onPreferenceChange(ToastStackHeightPreferenceKey.self) { height in
                guard height > 0 else { return }
                updateMeasuredExpandedHeight(height)
            }
            .onPreferenceChange(ToastCardHeightPreferenceKey.self) { heights in
                guard let frontID = visibleMessages.last?.id,
                      let height = heights[frontID],
                      height > 0 else { return }
                updateFrontCardHeight(height)
            }
            .onAppear {
                withAnimation(entranceAnimation) {
                    isVisible = true
                }
            }
            .onChange(of: model.dismissingID) { dismissingID in
                if dismissingID != nil {
                    dismissalLayoutHeight = containerHeight
                } else if dismissalLayoutHeight != nil {
                    withAnimation(promoteAnimation) {
                        dismissalLayoutHeight = nil
                    }
                }
            }
            .onChange(of: model.messages.count) { count in
                if count == 0 {
                    dismissalLayoutHeight = nil
                }
                if count == 1, isExpanded {
                    withAnimation(expandAnimation) {
                        isExpanded = false
                    }
                    onExpandChange(false)
                }
            }
        }
    }

    /// Hidden sizing pass for collapsed front-card height and expanded stack height.
    private var cardMeasurementStack: some View {
        VStack(spacing: UX.listSpacing) {
            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                measurementRow(for: message, isFront: index == visibleMessages.count - 1)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ToastStackHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func measurementRow(for message: EcosiaErrorToastMessage, isFront: Bool) -> some View {
        EcosiaErrorView(
            title: message.title,
            subtitle: message.subtitle,
            windowUUID: windowUUID,
            showsCloseButton: true,
            onCloseTapped: nil
        )
        .padding(.horizontal, .ecosia.space._m)
        .overlay {
            if isFront {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ToastCardHeightPreferenceKey.self,
                        value: [message.id: geometry.size.height]
                    )
                }
            }
        }
    }

    private var collapsedStack: some View {
        ZStack(alignment: .top) {
            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                let depthFromFront = visibleMessages.count - 1 - index
                let isFront = depthFromFront == 0
                let isDismissing = message.id == model.dismissingID

                collapsedWalletCard(
                    for: message,
                    depthFromFront: depthFromFront,
                    isFront: isFront,
                    isDismissing: isDismissing
                )
                .offset(y: CGFloat(index) * UX.stackPeek)
                .opacity(isDismissing ? 0 : 1)
                .animation(.easeOut(duration: UX.fadeDuration), value: isDismissing)
                .allowsHitTesting(isFront && !isDismissing)
                .zIndex(Double(index))
            }
        }
        .animation(promoteAnimation, value: layoutAnimationKey)
    }

    private var expandedStack: some View {
        VStack(spacing: UX.listSpacing) {
            ForEach(visibleMessages) { message in
                expandedRow(for: message)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func expandedRow(for message: EcosiaErrorToastMessage) -> some View {
        let isDismissing = message.id == model.dismissingID

        EcosiaErrorView(
            title: message.title,
            subtitle: message.subtitle,
            windowUUID: windowUUID,
            showsCloseButton: true,
            onCloseTapped: isDismissing ? nil : { dismiss(message) }
        )
        .padding(.horizontal, .ecosia.space._m)
        .opacity(isDismissing ? 0 : 1)
        .animation(.easeOut(duration: UX.fadeDuration), value: isDismissing)
        .allowsHitTesting(!isDismissing)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var entranceOffset: CGFloat {
        referenceCardHeight + .ecosia.space._1l
    }

    private var visibleMessages: [EcosiaErrorToastMessage] {
        Array(model.messages.suffix(UX.maxVisibleDepth))
    }

    private var canExpand: Bool {
        visibleMessages.count > 1
    }

    private var effectiveContainerHeight: CGFloat {
        dismissalLayoutHeight ?? containerHeight
    }

    private var containerHeight: CGFloat {
        isExpanded ? expandedHeight : collapsedHeight
    }

    private var referenceCardHeight: CGFloat {
        max(frontCardHeight, UX.minCardHeight)
    }

    private var collapsedHeight: CGFloat {
        referenceCardHeight + CGFloat(max(0, visibleMessages.count - 1)) * UX.stackPeek
    }

    private var expandedHeight: CGFloat {
        if let measuredExpandedHeight, measuredExpandedHeight > 0 {
            return measuredExpandedHeight
        }

        let estimatedCards = CGFloat(visibleMessages.count) * UX.minCardHeight
        let spacing = UX.listSpacing * CGFloat(max(0, visibleMessages.count - 1))
        return estimatedCards + spacing
    }

    private func updateFrontCardHeight(_ height: CGFloat) {
        guard abs(frontCardHeight - height) > 0.5 else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            frontCardHeight = height
        }
    }

    private func updateMeasuredExpandedHeight(_ height: CGFloat) {
        guard abs((measuredExpandedHeight ?? 0) - height) > 0.5 else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            measuredExpandedHeight = height
        }
    }

    private func scaleForDepth(_ depth: Int) -> CGFloat {
        switch depth {
        case 0: return 1
        case 1: return 327.0 / 343.0
        default: return 311.0 / 343.0
        }
    }

    @ViewBuilder
    private func collapsedWalletCard(
        for message: EcosiaErrorToastMessage,
        depthFromFront: Int,
        isFront: Bool,
        isDismissing: Bool
    ) -> some View {
        let showsCloseButton = isFront && !isDismissing
        let card = toastCard(
            for: message,
            showsCloseButton: showsCloseButton,
            showsShadow: isFront,
            onClose: { dismiss(message) }
        )

        Group {
            if isFront {
                card.scaleEffect(1, anchor: .top)
            } else {
                card
                    .scaleEffect(scaleForDepth(depthFromFront), anchor: .top)
                    .frame(height: UX.stackPeek, alignment: .top)
                    .clipped()
            }
        }
    }

    @ViewBuilder
    private func toastCard(
        for message: EcosiaErrorToastMessage,
        showsCloseButton: Bool,
        showsShadow: Bool,
        onClose: @escaping () -> Void
    ) -> some View {
        let content = EcosiaErrorView(
            title: message.title,
            subtitle: message.subtitle,
            windowUUID: windowUUID,
            showsCloseButton: true,
            onCloseTapped: showsCloseButton ? onClose : nil
        )
        .frame(minHeight: UX.minCardHeight, alignment: .center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, .ecosia.space._m)

        Group {
            if showsShadow {
                content.shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            } else {
                content
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private func toggleExpanded() {
        guard canExpand else { return }

        let willExpand = !isExpanded
        withAnimation(expandAnimation) {
            isExpanded = willExpand
        }
        onExpandChange(willExpand)
    }

    private func dismiss(_ message: EcosiaErrorToastMessage) {
        guard model.dismissingID == nil else { return }
        model.requestDismiss(id: message.id)
    }
}

@available(iOS 16.0, *)
private struct ToastCardHeightPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [UUID: CGFloat] = [:]

    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

@available(iOS 16.0, *)
private struct ToastStackHeightPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorToastStack_Previews: PreviewProvider {
    struct PreviewHost: View {
        @StateObject private var model = EcosiaErrorToastStackModel()

        var body: some View {
            EcosiaErrorToastStack(
                model: model,
                windowUUID: .XCTestDefaultUUID
            )
            .padding()
            .onAppear {
                model.append(subtitles: [
                    "You can upload up to 5 files per chat.",
                    "The file is too large, the maximum file size is 5MB.",
                    "The file type is not supported. Please upload a JPG, PNG, PDF or text file."
                ])
            }
        }
    }

    static var previews: some View {
        PreviewHost()
            .previewLayout(.sizeThatFits)
    }
}
#endif
