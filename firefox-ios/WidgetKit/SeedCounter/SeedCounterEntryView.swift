// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit
// Ecosia: import Ecosia so that Color.ecosiaBundledColorWithName and EcosiaColor are available.
// Note: importing Ecosia pulls a second `Environment` into scope; SwiftUI property wrappers
// must therefore be qualified as @SwiftUI.Environment to avoid ambiguity.
import Ecosia

struct SeedCounterEntryView: View {
    let entry: SeedCounterProvider.Entry

    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    // MARK: Colors

    private var countColor: Color {
        colorScheme == .dark ? .white : Color(uiColor: EcosiaColor.Gray70)
    }

    private var seedsLabelColor: Color {
        colorScheme == .dark ? Color(uiColor: EcosiaColor.Gray30) : Color(uiColor: EcosiaColor.Gray50)
    }

    // MARK: View

    var body: some View {
        ZStack {
            // Count block: leading 14, top 13
            VStack(alignment: .leading, spacing: 0) {
                countBlock
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
            .padding(.top, 13)

            // Jar: 80 × 82, horizontally centred, bottom 6
            VStack(spacing: 0) {
                Spacer()
                SeedJarView(levelProgress: entry.levelProgress)
                    .frame(width: 80, height: 82)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)
            }
        }
        .widgetBackground(Color.ecosiaBundledColorWithName("PrimaryBackground"))
        .widgetURL(seedCounterWidgetURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Count block

    private var countBlock: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(entry.seedCount)")
                .font(.system(size: 38, weight: .bold, design: .default))
                .kerning(-0.03 * 38)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(countColor)
                .widgetAccentableCompat()

            Text(String.SeedCounterWidgetSeedsLabel)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(seedsLabelColor)
        }
    }

    // MARK: Deep link

    private var seedCounterWidgetURL: URL {
        linkToContainingApp(query: "widget-seed-counter-open-impact")
    }

    // MARK: Accessibility

    private var accessibilityLabel: String {
        let progressPercent = Int(entry.levelProgress * 100)
        return "\(entry.seedCount) seeds. \(progressPercent) percent of the way to the next level."
    }
}

// MARK: - Additional localized string

extension String {
    static let SeedCounterWidgetSeedsLabel = NSLocalizedString(
        "Widget.SeedCounter.SeedsLabel",
        tableName: "Localizable",
        value: "seeds",
        comment: "Label shown below the seed count number in the 2×2 seed counter widget."
    )
}

// MARK: - Preview

struct SeedCounterEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SeedCounterEntryView(
                entry: SeedCounterEntry(date: .now, seedCount: 128, levelProgress: 0.62, isSignedIn: true)
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Signed in · light")

            SeedCounterEntryView(
                entry: SeedCounterEntry(date: .now, seedCount: 128, levelProgress: 0.62, isSignedIn: true)
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Signed in · dark")

            SeedCounterEntryView(
                entry: SeedCounterEntry(date: .now, seedCount: 2, levelProgress: 0.22, isSignedIn: false)
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Signed out")

            SeedCounterEntryView(
                entry: SeedCounterEntry(date: .now, seedCount: 0, levelProgress: 0, isSignedIn: false)
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Empty · 0 seeds")
        }
    }
}
#endif
