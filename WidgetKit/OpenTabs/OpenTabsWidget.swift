/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import UIKit
import Combine

struct OpenTabsWidget: Widget {
    private let kind: String = "Quick View"

     var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabProvider()) { entry in
            OpenTabsView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName(String.QuickViewGalleryTitle)
        .description(String.QuickViewGalleryDescription)
    }
}

struct OpenTabsView: View {
    let entry: OpenTabsEntry
        
    @Environment(\.widgetFamily) var widgetFamily
    
    @ViewBuilder
    func lineItemForTab(_ tab: SimpleTab) -> some View {

        VStack(alignment: .leading) {
            Link(destination: linkToContainingApp("?uuid=\(tab.uuid)", query: "widget-open-url")) {
                HStack(alignment: .center, spacing: 15) {
                    if (entry.favicons[tab.title!] != nil) {
                        (entry.favicons[tab.title!])!.resizable().frame(width: 16, height: 16)
                    } else {
                        Image("placeholderFavicon")
                            .foregroundColor(.init("widgetText"))
                            .frame(width: 16, height: 16)
                    }
                    
                    Text(tab.title!)
                        .foregroundColor(.init("widgetText"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                }.padding(.horizontal)
            }
            
            Rectangle()
                .fill(Color("separator"))
                .frame(height: 1.0)
                .padding(.leading, 45)
                .padding(.trailing, 16)
        }
    }
    
    var openFirefoxButton: some View {
        HStack(alignment: .center, spacing: 15) {
            Image("openFirefox").foregroundColor(.init("widgetText"))
            Text(String.OpenFirefoxLabel).foregroundColor(.init("widgetText")).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
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
                VStack {
                    Text(String.NoOpenTabsLabel)
                    HStack {
                        Spacer()
                        Image("openFirefox").foregroundColor(.init("widgetText"))
                        Text(String.OpenFirefoxLabel).foregroundColor(.init("widgetText")).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
                        Spacer()
                    }.padding(10)
                }.foregroundColor(.init("widgetText"))
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                        lineItemForTab(tab)
                    }
                    
                    if (entry.tabs.count > numberOfTabsToDisplay) {
                        HStack(alignment: .center, spacing: 15) {
                            Image("openFirefox").foregroundColor(.init("widgetText")).frame(width: 16, height: 16)
                            Text(String.localizedStringWithFormat(String.MoreTabsLabel, (entry.tabs.count - numberOfTabsToDisplay)))
                                .foregroundColor(.init("widgetText")).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
                            Spacer()
                        }.padding([.horizontal])
                    } else {
                        openFirefoxButton
                    }
                    
                    Spacer()
                }.padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((Color("backgroundColor")))
    }
    
    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}
