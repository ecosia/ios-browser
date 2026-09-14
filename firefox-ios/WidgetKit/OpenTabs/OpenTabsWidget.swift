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
                .widgetTheme()
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName(String.QuickViewGalleryTitle)
        .description(String.QuickViewGalleryDescriptionV2)
        .contentMarginsDisabled()
    }
}

struct OpenTabsView: View {
    let entry: OpenTabsEntry

    /* Ecosia: Update Environment state definition — `import Ecosia` reintroduces an ambiguous
       `Environment`, so both property wrappers stay explicitly qualified.
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.theme) private var theme
     */
    @SwiftUI.Environment(\.widgetFamily)
    var widgetFamily
    @SwiftUI.Environment(\.theme)
    private var theme

    /* Ecosia: Widget colours come from the Ecosia bundle, not the Firefox theme. 155.1 funnels
       every content colour through this one property, so the dozen per-call-site overrides Ecosia
       used to carry collapse into this single substitution.
    private var contentColor: Color { Color(uiColor: theme.colors.textPrimary) }
     */
    private var contentColor: Color { .ecosiaBundledColorWithName("PrimaryText") }

    @ViewBuilder
    func lineItemForTab(_ tab: SimpleTab) -> some View {
        let query = widgetFamily == .systemMedium ? "widget-tabs-medium-open-url" : "widget-tabs-large-open-url"
        VStack(alignment: .leading) {
            Link(destination: linkToContainingApp("?uuid=\(tab.uuid)", query: query)) {
                HStack(alignment: .center, spacing: 15) {
                    if let favIcon = entry.favicons[tab.imageKey] {
                        if #available(iOS 18.0, *) {
                            favIcon.resizable()
                                .widgetAccentedRenderingMode(.accentedDesaturated)
                                .frame(width: 16, height: 16)
                                .foregroundColor(contentColor)
                        } else {
                            favIcon.resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(contentColor)
                        }
                    } else {
                        globeIconView
                    }

                    Text(tab.title ?? "")
                        .foregroundColor(contentColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                    Spacer()
                }.padding(.horizontal)
            }

            // Separator
            Rectangle()
                /* Ecosia: update color
                .fill(Color(uiColor: theme.colors.borderPrimary))
                 */
                .fill(Color.ecosiaBundledColorWithName("Border"))
                .frame(height: 0.5)
                .padding(.leading, 45)
        }
    }

    @ViewBuilder
    private var globeIconView: some View {
        if #available(iOS 18.0, *) {
            Image(decorative: StandardImageIdentifiers.Large.globe)
                .widgetAccentedRenderingMode(.accentedDesaturated)
                .foregroundColor(contentColor)
                .frame(width: 16, height: 16)
        } else {
            Image(decorative: StandardImageIdentifiers.Large.globe)
                .foregroundColor(contentColor)
                .frame(width: 16, height: 16)
        }
    }

    var emptyView: some View {
        VStack {
            Text(String.NoOpenTabsLabel)
                .foregroundStyle(contentColor)
            HStack {
                Spacer()
                /* Ecosia: Update image
                Image(decorative: StandardImageIdentifiers.Small.externalLink)
                 */
                Image(decorative: "openEcosia", bundle: .ecosia)
                    .foregroundColor(contentColor)
                Text(String.OpenFirefoxLabel)
                    .foregroundColor(contentColor)
                    .lineLimit(1)
                    .font(.footnote.weight(.semibold))
                Spacer()
            }.padding(10)
        }
    }

    var tabsView: some View {
        VStack(spacing: 8) {
            ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                lineItemForTab(tab)
            }

            if entry.tabs.count > numberOfTabsToDisplay {
                HStack(alignment: .center, spacing: 15) {
                    /* Ecosia: Update image
                    Image(decorative: StandardImageIdentifiers.Small.externalLink)
                     */
                    Image(decorative: "openEcosia", bundle: .ecosia)
                        .foregroundColor(contentColor)
                        .frame(width: 16, height: 16)
                    Text(
                        String.localizedStringWithFormat(
                            String.MoreTabsLabel,
                            (entry.tabs.count - numberOfTabsToDisplay)
                        )
                    )
                    .foregroundColor(contentColor)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    Spacer()
                }.padding([.horizontal])
            } else {
                /* Ecosia: Rename from openFirefoxButton
                openFirefoxButton
                 */
                openEcosiaButton
            }

            Spacer()
        }.padding(.top, 14)
    }

    /* Ecosia: Rename from openFirefoxButton
    var openFirefoxButton: some View {
     */
    var openEcosiaButton: some View {
        HStack(alignment: .center, spacing: 15) {
            /* Ecosia: Update image
            Image(decorative: StandardImageIdentifiers.Small.externalLink)
             */
            Image(decorative: "openEcosia", bundle: .ecosia)
                .foregroundColor(contentColor)
            Text(String.OpenFirefoxLabel)
                .foregroundColor(contentColor)
                .lineLimit(1)
                .font(.footnote.weight(.semibold))
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
        .widgetBackground(
            LinearGradient(
                gradient: theme.colors.gradientWidgetSurface.swiftUI,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        )
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
