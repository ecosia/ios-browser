// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct VoiceSearchProvider: TimelineProvider {
    func placeholder(in context: Context) -> VoiceSearchEntry {
        VoiceSearchEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (VoiceSearchEntry) -> Void) {
        completion(VoiceSearchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VoiceSearchEntry>) -> Void) {
        let entry = VoiceSearchEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct VoiceSearchEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View

struct VoiceSearchWidgetView: View {
    var entry: VoiceSearchProvider.Entry

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)

                Text(String.VoiceSearchWidgetLabel)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("searchButtonColorTwo"),
                    Color("searchButtonColorOne")
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        )
        .widgetURL(linkToContainingApp(query: "widget-voice-search"))
    }
}

// MARK: - Widget Configuration

struct VoiceSearchWidget: Widget {
    private let kind = "Voice Search"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VoiceSearchProvider()) { entry in
            VoiceSearchWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName(String.VoiceSearchWidgetTitle)
        .description(String.VoiceSearchWidgetDescription)
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

struct VoiceSearchWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            VoiceSearchWidgetView(entry: VoiceSearchEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            VoiceSearchWidgetView(entry: VoiceSearchEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - Strings

extension String {
    static let VoiceSearchWidgetLabel = MZLocalizedString(
        key: "TodayWidget.VoiceSearchLabel",
        tableName: "Today",
        value: "Voice\nSearch",
        comment: "Voice Search widget label"
    )
    static let VoiceSearchWidgetTitle = MZLocalizedString(
        key: "TodayWidget.VoiceSearchTitle",
        tableName: "Today",
        value: "Voice Search",
        comment: "Voice Search widget gallery title"
    )
    static let VoiceSearchWidgetDescription = MZLocalizedString(
        key: "TodayWidget.VoiceSearchDescription",
        tableName: "Today",
        value: "Tap to search the web with your voice using Ecosia.",
        comment: "Voice Search widget gallery description"
    )
}
#endif
