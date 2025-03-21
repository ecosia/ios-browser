// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import Common
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
// | | | +--------------------------+ | |FXICON | | |   |  |
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
                    ContainerRelativeShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: link.backgroundColors),
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                }

                VStack(alignment: .center, spacing: 50.0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
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
                        Spacer()
                        /* Ecosia: Update image
                        if link == .search && isSmall {
                            Image(decorative: StandardImageIdentifiers.Large.search)
                                .scaledToFit()
                                .frame(height: 24.0)
                        } else {
                            Image(decorative: link.imageName)
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                         */
                        Image(decorative: link.imageName, bundle: .ecosia)
                            .scaledToFit()
                            .frame(height: 24.0)
                            .foregroundColor(link.iconColor)
                    }
                    if isSmall {
                        HStack(alignment: .bottom) {
                            Spacer()
                            /* Ecosia: Update image
                            Image(decorative: "faviconFox")
                             .scaledToFit()
                             .frame(height: 24.0)
                            */
                            Image(decorative: "iconLogo", bundle: .ecosia)
                                .scaledToFit()
                                .frame(height: 24.0)
                                .foregroundColor(link.iconColor)
                        }
                    }
                }
                /* Ecosia: Update color
                .foregroundColor(Color("widgetLabelColors"))
                 */
                .foregroundColor(Color.ecosiaBundledColorWithName("widgetLabelColors"))
                .padding([.horizontal, .vertical], paddingValue)
            }
        }
    }
}
#endif
