// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit
import Shared

struct MediumWithCounterQuickLinkView: View {
    var entry: QuickLinkWithCounterIntentProvider.Entry
    
    @ViewBuilder
    var body: some View {
        let vStack =
        VStack(alignment: .center) {
            Image("logoLarge")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 38)
                .widgetURL(entry.link.smallWidgetUrl)
            GlobalCounter(treesPlanted: String.formattedNumberOfTreesForValue(entry.infoModel.totalTrees))
            CounterBar()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("PrimaryBackground"))
        if #available(iOS 17.0, *) {
            vStack.containerBackground(.clear, for: .widget)
        }
    }
}

struct MediumQuickLinkWidgetWithCounter: Widget {
    private let kind: String = "Quick Actions - Medium With Counter"
    
    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: QuickActionIntent.self, provider: QuickLinkWithCounterIntentProvider()) { entry in
            MediumWithCounterQuickLinkView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName(String.QuickActionsGalleryTitle)
        .description(String.QuickActionGalleryDescription)
    }
}

struct MediumWithCounterQuickActionsPreviews: PreviewProvider {
    static let model = WidgetKitInfoModel(totalTrees: 180_000_000)
    static let testEntry = QuickLinkWithCounterEntry(date: Date(),
                                                     link: .search,
                                                     infoModel: Self.model)
    static var previews: some View {
        Group {
            MediumWithCounterQuickLinkView(entry: Self.testEntry)
                .environment(\.colorScheme, .dark)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

struct GlobalCounter: View {
    
    var treesPlanted: String = "trees_planted_placeholder"
    
    var body: some View {
        HStack(alignment: .center,
               spacing: 8) {
            Image("hand")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 38)
            VStack(alignment: .leading) {
                Text(treesPlanted)
                    .font(.title2)
                    .bold()
                Text("trees planted by Ecosia the community")
                    .font(.footnote)
            }
        }
               .padding(EdgeInsets(top: 0,
                                   leading: 8,
                                   bottom: 0,
                                   trailing: 8))
        
    }
}

struct CounterBar: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color("TertiaryBackground"))
                .frame(height: 45)
            HStack {
                Image("openEcosia")
                    .foregroundColor(.init("PrimaryBrand"))
                    .padding(.leading)
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 0,
                            leading: 8,
                            bottom: 0,
                            trailing: 8))
        .contentShape(Rectangle())
    }
}

extension String {
    
    static func formattedNumberOfTreesForValue(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.currencyGroupingSeparator = ","
        return formatter.string(from: .init(integerLiteral: value)) ?? ""
    }
}

#endif
