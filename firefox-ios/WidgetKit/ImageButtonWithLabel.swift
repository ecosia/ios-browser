// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import Common
// Ecosia: Add import for Ecosia bundle image and color access
import Ecosia

// View for Quick Action Widget Buttons (Small & Medium)
// +-------------------------------------------------------+
// | +--------+                                            |
// | | ZSTACK |                                            |
// | +--------+                                            |
// | +--------------------------------------------------+  |
// | |+-------+                                         |  |
// | ||VSTACK |                                         |  |
// | |+-------+                                         |  |
// | | +---------------------------------------------+  |  |
// | | |+-------+                                    |  |  |
// | | ||HSTACK | +--------+-----+ +--------------+  |  |  |
// | | |+-------+ | VSTACK |     | |+----------+  |  |  |  |
// | | |          +--------+     | || lOGO FOR |  |  |  |  |
// | | |          | +----------+ | ||  WIDGET  |  |  |  |  |
// | | |          | | LABEL OF | | ||  ACTION  |  |  |  |  |
// | | |          | | SELECTED | | |+----------+  |  |  |  |
// | | |          | |  ACTION  | | |              |  |  |  |
// | | |          | +----------+ | |              |  |  |  |
// | | |          |              | |              |  |  |  |
// | | |          +--------------+ +--------------+  |  |  |
// | | |                                             |  |  |
// | | |                                             |  |  |
// | | +---------------------------------------------+  |  |
// | |                                                  |  |
// | | +--------------------------------------------+   |  |
// | | | +--------------------------+ +-----------+ |   |  |
// | | | | HSTACK (if small widget) | | +-------+ | |   |  |
// | | | +--------------------------+ | |APPICON| | |   |  |  // Ecosia: Renamed from FXICON
// | | |                              | +-------+ | |   |  |
// | | |                              |           | |   |  |
// | | |                              |           | |   |  |
// | | |                              +-----------+ |   |  |
// | | |                                            |   |  |
// | | +--------------------------------------------+   |  |
// | |                                                  |  |
// | |                                                  |  |
// | |                                                  |  |
// | +--------------------------------------------------+  |
// |                                                       |
// +-------------------------------------------------------+

struct ImageButtonWithLabel: View {
    /* Ecosia: `import Ecosia` brings a second `Environment` into scope, so SwiftUI's property
       wrapper must be qualified. 155.1 added this theme environment value.
    @Environment(\.theme) private var theme
     */
    @SwiftUI.Environment(\.theme)
    private var theme
    var isSmall: Bool
    var link: QuickLink

    var paddingValue: CGFloat {
        if isSmall {
            return 10.0
        } else {
            return 8.0
        }
    }

    var body: some View {
        Link(destination: isSmall ? link.smallWidgetUrl : link.mediumWidgetUrl) {
            ZStack(alignment: .leading) {
                if !isSmall {
                    background
                }

                VStack(alignment: .center, spacing: 50.0) {
                    HStack(alignment: .top) {
                        label
                        Spacer()
                        logo
                    }
                    if isSmall {
                        icon
                    }
                }
                /* Ecosia: Update color
                .foregroundColor(link.foregroundColor(for: theme))
                 */
                .foregroundColor(Color.ecosiaBundledColorWithName("widgetLabelColors"))
                .padding([.horizontal, .vertical], paddingValue)
            }
        }
    }

    /* Ecosia: Widget colours come from the Ecosia bundle, not the Firefox theme. 155.1 replaced this
       with a theme-driven background plus a new `BackgroundContent` view (commented out at the bottom
       of this file); both need `QuickLink.gradient(for:)` / `tintedBackgroundColor(for:)`, which are
       commented out in QuickLink.swift for the same reason.
    @ViewBuilder
    private var background: some View {
        if #available(iOS 16.0, *) {
            BackgroundContent(link: link)
        } else {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        gradient: link.gradient(for: theme),
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
        }
    }
     */
    private var background: some View {
        return ContainerRelativeShape()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: link.backgroundColors),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            )
            .widgetAccentableCompat()
    }

    private var label: some View {
        return VStack(alignment: .leading) {
            if isSmall {
                Text(link.label)
                    .font(.headline)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1000)
                    // Ecosia: add color
                    .foregroundColor(link.textColor)
            } else {
                Text(link.label)
                    .font(.footnote)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1000)
                    // Ecosia: add color
                    .foregroundColor(link.textColor)
            }
        }
    }

    private var logo: some View {
        /* Ecosia: Update image and color — use Ecosia bundle images
        let isSearchSmall = (link == .search && isSmall)
        let imageName = isSearchSmall ? StandardImageIdentifiers.Large.search : link.imageName

        if #available(iOSApplicationExtension 18.0, *) {
            Image(decorative: imageName)
                .widgetAccentedRenderingMode(.accentedDesaturated)
                .scaledToFit()
                .frame(height: 24.0)
        } else {
            Image(decorative: imageName)
                .scaledToFit()
                .frame(height: 24.0)
        }
         */
        return Image(decorative: link.imageName, bundle: .ecosia)
            .scaledToFit()
            .frame(height: 24.0)
            .foregroundColor(link.iconColor)
    }

    private var icon: some View {
        return HStack(alignment: .bottom) {
            Spacer()
            /* Ecosia: Replace fox icon with Ecosia app icon from Ecosia bundle
            if #available(iOSApplicationExtension 18.0, *) {
                Image(decorative: "faviconFox")
                    .widgetAccentedRenderingMode(.accentedDesaturated)
                    .scaledToFit()
                    .frame(height: 24.0)
            } else {
                Image(decorative: "faviconFox")
                    .scaledToFit()
                    .frame(height: 24.0)
            }
             */
            Image(decorative: "iconLogo", bundle: .ecosia)
                .scaledToFit()
                .frame(height: 24.0)
                .foregroundColor(link.iconColor)
        }
    }
}

/* Ecosia: New in 155.1 and unused here — see the `background` comment above.
@available(iOS 16.0, *)
struct BackgroundContent: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.theme) private var theme
    var link: QuickLink

    var body: some View {
        if renderingMode == .accented {
            ContainerRelativeShape()
                .fill(link.tintedBackgroundColor(for: theme))
        } else {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        gradient: link.gradient(for: theme),
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
        }
    }
}
 */
#endif
