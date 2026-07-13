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
        static let fadeDuration: TimeInterval = 0.25
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
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
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
    @State private var cardHeights: [UUID: CGFloat] = [:]
    @State private var dismissalLayoutHeight: CGFloat?

    private enum UX {
        static let minCardHeight: CGFloat = 56
        static let stackPeek: CGFloat = .ecosia.space._1s
        static let listSpacing: CGFloat = .ecosia.space._1s
        static let fadeDuration: TimeInterval = 0.25
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

    private var promoteSpring: Animation {
        .spring(response: 0.38, dampingFraction: 0.86)
    }

    private var layoutAnimationKey: String {
        let messageIDs = model.messages.map(\.id.uuidString).joined(separator: "-")
        let dismissingID = model.dismissingID?.uuidString ?? "none"
        return "\(isExpanded)-\(messageIDs)-\(dismissingID)"
    }

    public var body: some View {
        if !model.messages.isEmpty {
            ZStack(alignment: .top) {
                ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                    let depthFromFront = visibleMessages.count - 1 - index
                    let isFront = depthFromFront == 0
                    let isDismissing = message.id == model.dismissingID

                    toastCard(
                        for: message,
                        showsCloseButton: (isExpanded || isFront) && !isDismissing,
                        onClose: { dismiss(message) }
                    )
                    .scaleEffect(
                        x: isExpanded ? 1 : scaleForDepth(depthFromFront),
                        y: 1,
                        anchor: .top
                    )
                    .offset(y: yOffset(for: index))
                    .opacity(isDismissing ? 0 : 1)
                    .animation(.easeOut(duration: UX.fadeDuration), value: isDismissing)
                    .allowsHitTesting(isExpanded || (isFront && !isDismissing))
                    .zIndex(Double(index))
                }
            }
            .frame(height: effectiveContainerHeight, alignment: .top)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { toggleExpanded() }
            .animation(promoteSpring, value: layoutAnimationKey)
            .offset(y: isVisible ? 0 : -(referenceCardHeight + .ecosia.space._1l))
            .opacity(isVisible ? 1 : 0)
            .onPreferenceChange(ToastCardHeightPreferenceKey.self, perform: updateCardHeights)
            .onAppear {
                withAnimation(.easeOut(duration: UX.fadeDuration)) {
                    isVisible = true
                }
            }
            .onChange(of: model.dismissingID) { dismissingID in
                if dismissingID != nil {
                    dismissalLayoutHeight = containerHeight
                } else if dismissalLayoutHeight != nil {
                    withAnimation(promoteSpring) {
                        dismissalLayoutHeight = nil
                    }
                }
            }
            .onChange(of: model.messages.count) { count in
                if count == 0 {
                    dismissalLayoutHeight = nil
                }
                if count == 1, isExpanded {
                    withAnimation(promoteSpring) {
                        isExpanded = false
                    }
                    onExpandChange(false)
                }
            }
        }
    }

    private var visibleMessages: [EcosiaErrorToastMessage] {
        Array(model.messages.suffix(UX.maxVisibleDepth))
    }

    private var canExpand: Bool {
        visibleMessages.count > 1
    }

    private var containerHeight: CGFloat {
        isExpanded ? expandedHeight : collapsedHeight
    }

    private var effectiveContainerHeight: CGFloat {
        dismissalLayoutHeight ?? containerHeight
    }

    private var referenceCardHeight: CGFloat {
        guard let frontID = visibleMessages.last?.id else { return UX.minCardHeight }
        return max(cardHeights[frontID] ?? UX.minCardHeight, UX.minCardHeight)
    }

    private var collapsedHeight: CGFloat {
        referenceCardHeight + CGFloat(max(0, visibleMessages.count - 1)) * UX.stackPeek
    }

    private var expandedHeight: CGFloat {
        guard !visibleMessages.isEmpty else { return UX.minCardHeight }

        let heights = visibleMessages.map { max(cardHeights[$0.id] ?? UX.minCardHeight, UX.minCardHeight) }
        let spacing = UX.listSpacing * CGFloat(max(0, visibleMessages.count - 1))
        return heights.reduce(0, +) + spacing
    }

    private func updateCardHeights(_ newHeights: [UUID: CGFloat]) {
        let activeIDs = Set(model.messages.map(\.id))
        var updated = cardHeights.filter { activeIDs.contains($0.key) }

        for (id, height) in newHeights where activeIDs.contains(id) {
            let resolved = max(height, UX.minCardHeight)
            if let existing = updated[id] {
                // Ignore sub-point churn from text re-measurement during animations.
                if abs(existing - resolved) > 0.5 {
                    updated[id] = resolved
                }
            } else {
                updated[id] = resolved
            }
        }

        guard updated != cardHeights else { return }
        cardHeights = updated
    }

    private func yOffset(for index: Int) -> CGFloat {
        if isExpanded {
            var offset: CGFloat = 0
            for priorIndex in 0..<index {
                let message = visibleMessages[priorIndex]
                let height = max(cardHeights[message.id] ?? UX.minCardHeight, UX.minCardHeight)
                offset += height + UX.listSpacing
            }
            return offset
        }
        return CGFloat(index) * UX.stackPeek
    }

    private func scaleForDepth(_ depth: Int) -> CGFloat {
        switch depth {
        case 0: return 1
        case 1: return 327.0 / 343.0
        default: return 311.0 / 343.0
        }
    }

    @ViewBuilder
    private func toastCard(
        for message: EcosiaErrorToastMessage,
        showsCloseButton: Bool,
        onClose: @escaping () -> Void
    ) -> some View {
        EcosiaErrorView(
            title: message.title,
            subtitle: message.subtitle,
            windowUUID: windowUUID,
            showsCloseButton: true,
            onCloseTapped: showsCloseButton ? onClose : nil
        )
        .frame(minHeight: UX.minCardHeight, alignment: .center)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ToastCardHeightPreferenceKey.self,
                    value: [message.id: geometry.size.height]
                )
            }
        }
        .padding(.horizontal, .ecosia.space._m)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private func toggleExpanded() {
        guard canExpand else { return }

        let willExpand = !isExpanded
        withAnimation(promoteSpring) {
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
