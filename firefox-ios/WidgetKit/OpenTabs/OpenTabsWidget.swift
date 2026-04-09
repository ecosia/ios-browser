// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit
import UIKit
import Combine
import Common
// Ecosia: Additional imports for Ecosia framework and suggested sites updates
import Ecosia
import Storage

struct OpenTabsWidget: Widget {
    private let kind = "Quick View"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabProvider()) { entry in
            OpenTabsView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName(String.QuickViewGalleryTitle)
        .description(String.QuickViewGalleryDescriptionV2)
        .contentMarginsDisabled()
    }
}

struct OpenTabsView: View {
    let entry: OpenTabsEntry

    /* Ecosia: Update Environment state definition
    @Environment(\.widgetFamily)
     */
    @SwiftUI.Environment(\.widgetFamily)
    var widgetFamily

    @ViewBuilder
    func lineItemForTab(_ tab: SimpleTab) -> some View {
        let query = widgetFamily == .systemMedium ? "widget-tabs-medium-open-url" : "widget-tabs-large-open-url"
        VStack(alignment: .leading) {
            Link(destination: linkToContainingApp("?uuid=\(tab.uuid)", query: query)) {
                HStack(alignment: .center, spacing: 15) {
                    if let favIcon = entry.favicons[tab.imageKey] {
                        favIcon.resizable().frame(width: 16, height: 16)
                            /* Ecosia: update color
                            .foregroundColor(Color("openTabsContentColor"))
                             */
                            .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                    } else {
                        Image(decorative: StandardImageIdentifiers.Large.globe)
                            /* Ecosia: update color
                            .foregroundColor(Color("openTabsContentColor"))
                             */
                            .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                            .frame(width: 16, height: 16)
                    }

                    Text(tab.title ?? "")
                        /* Ecosia: update color
                        .foregroundColor(Color("openTabsContentColor"))
                         */
                        .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                    Spacer()
                }.padding(.horizontal)
            }

            // Separator
            Rectangle()
                /* Ecosia: update color
                .fill(Color("separatorColor"))
                 */
                .fill(Color.ecosiaBundledColorWithName("Border"))
                .frame(height: 0.5)
                .padding(.leading, 45)
        }
    }

    var emptyView: some View {
        VStack {
            Text(String.NoOpenTabsLabel)
            HStack {
                Spacer()
                /* Ecosia: Update image
                Image(decorative: StandardImageIdentifiers.Small.externalLink)
                 */
                Image(decorative: "openEcosia", bundle: .ecosia)
                    /* Ecosia: update color
                    .foregroundColor(Color("openTabsContentColor"))
                     */
                    .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                Text(String.OpenFirefoxLabel)
                    /* Ecosia: update color
                    .foregroundColor(Color("openTabsContentColor"))
                     */
                    .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                Spacer()
            }.padding(10)
        }
        // Ecosia: update color
        .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
    }

    var tabsView: some View {
        VStack(spacing: 8) {
            ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                lineItemForTab(tab)
            }

            if entry.tabs.count > numberOfTabsToDisplay {
                HStack(alignment: .center, spacing: 15) {
                    /* Ecosia: Update image and color
                    Image(decorative: StandardImageIdentifiers.Small.externalLink)
                        .foregroundColor(Color("openTabsContentColor"))
                     */
                    Image(decorative: "openEcosia", bundle: .ecosia)
                        .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                        .frame(width: 16, height: 16)
                    Text(
                        String.localizedStringWithFormat(
                            String.MoreTabsLabel,
                            (entry.tabs.count - numberOfTabsToDisplay)
                        )
                    )
                    /* Ecosia: update color
                    .foregroundColor(Color("openTabsContentColor"))
                     */
                    .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    Spacer()
                }.padding([.horizontal])
            } else {
                openEcosiaButton
            }

            Spacer()
        }.padding(.top, 14)
    }

    // Ecosia: Rename from openFirefoxButton
    var openEcosiaButton: some View {
        HStack(alignment: .center, spacing: 15) {
            /* Ecosia: Update image and color
            Image(decorative: StandardImageIdentifiers.Small.externalLink).foregroundColor(Color("openTabsContentColor"))
             */
            Image(decorative: "openEcosia", bundle: .ecosia)
                .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
            Text(String.OpenFirefoxLabel)
                /* Ecosia: update color
                .foregroundColor(Color("openTabsContentColor"))
                 */
                .foregroundColor(.ecosiaBundledColorWithName("PrimaryText"))
                .lineLimit(1)
                .font(.system(size: 13, weight: .semibold, design: .default))
            Spacer()
        }.padding([.horizontal])
    }

    var numberOfTabsToDisplay: Int {
        if widgetFamily == .systemMedium {
            return 3
        } else {
            return 8
        }
    }

    var body: some View {
        Group {
            if entry.tabs.isEmpty {
                emptyView
            } else {
                tabsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        /* Ecosia: update color
        .widgetBackground(Color("backgroundColor"))
         */
        .background(Color.ecosiaBundledColorWithName("PrimaryBackground"))
    }

    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}

struct OpenTabsPreview: PreviewProvider {
    static let favIcons = ["globe":
                            Image(decorative: StandardImageIdentifiers.Large.globe)]
    static let tabs = [SimpleTab(lastUsedTime: nil)]
    static let testEntry = OpenTabsEntry(date: Date(),
                                         favicons: favIcons,
                                         tabs: [SimpleTab]())
    static var previews: some View {
        Group {
            OpenTabsView(entry: testEntry)
        }
    }
}
