// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct PlanetPulseView: View {
    @SwiftUI.Environment(\.widgetFamily)
    private var widgetFamily

    let entry: PlanetPulseEntry
    private let spacing = EcosiaSpacing()

    var body: some View {
        VStack(alignment: .leading, spacing: spacing._1s) {
            header
            title

            if widgetFamily == .systemMedium {
                bodyText
                source
            }

            Spacer(minLength: 0)
            callToAction
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(palette.secondary)
        .widgetBackground(themedBackground)
        .animation(.easeInOut(duration: 0.65), value: entry.card.id)
        .widgetURL(entry.destinationURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(entry.card.callToAction)
    }

    private var header: some View {
        HStack(spacing: spacing._2s) {
            headerIcon
            Text(eyebrow)
                .contentTransition(.numericText())
            Spacer(minLength: spacing._2s)
            Image(decorative: "iconLogo", bundle: .ecosia)
                .renderingMode(.original)
                .resizable()
                .planetPulseWidgetFullColor()
                .scaledToFit()
                .frame(width: spacing._l, height: spacing._l)
                .accessibilityHidden(true)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(palette.secondary)
    }

    private var headerIcon: some View {
        Image(systemName: symbolName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(palette.secondary)
            .padding(spacing._2s)
            .background(palette.accent.opacity(0.16), in: Circle())
            .contentTransition(.opacity)
            .widgetAccentableCompat()
            .accessibilityHidden(true)
    }

    private var title: some View {
        Text(entry.card.title)
            .font(.headline.weight(.bold))
            .foregroundStyle(palette.secondary)
            .contentTransition(.numericText())
            .lineLimit(widgetFamily == .systemSmall ? 4 : 2)
            .minimumScaleFactor(0.85)
    }

    private var bodyText: some View {
        Text(entry.card.body)
            .font(.subheadline)
            .foregroundStyle(palette.secondary)
            .contentTransition(.numericText())
            .lineLimit(2)
    }

    @ViewBuilder
    private var source: some View {
        if let sourceName = entry.card.sourceName {
            HStack(spacing: spacing._2s) {
                Text(sourceName)
                    .contentTransition(.numericText())
                if let publishedAt = entry.card.publishedAt {
                    Text("·")
                    Text(publishedAt, format: .dateTime.day().month(.abbreviated))
                        .contentTransition(.numericText())
                }
            }
            .font(.caption2)
            .foregroundStyle(palette.secondary.opacity(0.82))
        }
    }

    private var callToAction: some View {
        callToActionLabel
            .foregroundStyle(palette.secondary)
            .padding(.horizontal, spacing._1s)
            .padding(.vertical, spacing._2s)
            .background(palette.accent.opacity(0.18), in: Capsule())
            .widgetAccentableCompat()
    }

    private var callToActionLabel: some View {
        HStack(spacing: spacing._2s) {
            Text(entry.card.callToAction)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())
            Image(systemName: "arrow.right")
                .accessibilityHidden(true)
        }
        .font(.caption.weight(.semibold))
    }

    private var themedBackground: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [palette.backgroundStart, palette.backgroundEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(palette.glow.opacity(0.35))
                .frame(width: spacing._8l, height: spacing._8l)
                .blur(radius: spacing._1l)
                .offset(x: spacing._2l, y: -spacing._2l)

            Image(systemName: symbolName)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(palette.secondary.opacity(0.13))
                .scaleEffect(2.2)
                .offset(x: spacing._l, y: spacing._m)
                .accessibilityHidden(true)
        }
    }

    private var eyebrow: String {
        switch entry.card.kind {
        case .action:
            return .localized(.planetPulseActionEyebrow)
        case .insight:
            return .localized(.planetPulseInsightEyebrow)
        }
    }

    private var accessibilityLabel: String {
        [eyebrow, entry.card.title, entry.card.body]
            .joined(separator: ". ")
    }

    private var palette: PlanetPulsePalette {
        resolvedAppearance.palette
    }

    private var resolvedAppearance: PlanetPulseWidgetAppearance {
        guard entry.appearance == .planetMix else {
            return entry.appearance
        }

        switch entry.card.id {
        case "city-trees-cooling", "cooler-wash":
            return .ocean
        case "trees-milestone", "use-leftovers", "lighter-trip", "plant-forward-meal":
            return .sunrise
        default:
            return .forest
        }
    }

    private var symbolName: String {
        switch entry.card.id {
        case "city-trees-cooling":
            return "thermometer.sun.fill"
        case "underground-forest":
            return "tree.fill"
        case "cerrado-corridor":
            return "pawprint.fill"
        case "trees-milestone":
            return "sparkles"
        case "wildfire-recovery":
            return "flame.fill"
        case "use-leftovers", "plant-forward-meal":
            return "fork.knife"
        case "repair-before-replacing":
            return "wrench.and.screwdriver.fill"
        case "lighter-trip":
            return "figure.walk"
        case "cooler-wash":
            return "drop.fill"
        case "borrow-before-buying":
            return "arrow.triangle.2.circlepath"
        default:
            return entry.card.kind == .action ? "leaf.fill" : "globe.europe.africa.fill"
        }
    }
}

@available(iOS 17.0, *)
private struct PlanetPulsePalette {
    let backgroundStart: Color
    let backgroundEnd: Color
    let secondary: Color
    let accent: Color
    let glow: Color
}

@available(iOS 17.0, *)
private extension PlanetPulseWidgetAppearance {
    var palette: PlanetPulsePalette {
        switch self {
        case .planetMix, .forest:
            return PlanetPulsePalette(
                backgroundStart: Color(red: 0.07, green: 0.24, blue: 0.19),
                backgroundEnd: Color(red: 0.12, green: 0.39, blue: 0.29),
                secondary: Color(red: 0.87, green: 0.91, blue: 0.82),
                accent: Color(red: 0.78, green: 0.95, blue: 0.48),
                glow: Color(red: 0.67, green: 0.89, blue: 0.36)
            )
        case .ecosiaClassic:
            return PlanetPulsePalette(
                backgroundStart: Color.ecosiaBundledColorWithName("PrimaryBackground"),
                backgroundEnd: Color.ecosiaBundledColorWithName("PrimaryBackground"),
                secondary: Color.ecosiaBundledColorWithName("PrimaryText"),
                accent: Color.ecosiaBundledColorWithName("PrimaryBrand"),
                glow: Color.ecosiaBundledColorWithName("TertiaryBackground")
            )
        case .ocean:
            return PlanetPulsePalette(
                backgroundStart: Color(red: 0.02, green: 0.22, blue: 0.31),
                backgroundEnd: Color(red: 0.02, green: 0.43, blue: 0.49),
                secondary: Color(red: 0.77, green: 0.92, blue: 0.92),
                accent: Color(red: 0.41, green: 0.93, blue: 0.82),
                glow: Color(red: 0.31, green: 0.84, blue: 0.95)
            )
        case .sunrise:
            return PlanetPulsePalette(
                backgroundStart: Color(red: 1.00, green: 0.89, blue: 0.56),
                backgroundEnd: Color(red: 0.98, green: 0.65, blue: 0.45),
                secondary: Color(red: 0.34, green: 0.18, blue: 0.27),
                accent: Color(red: 0.69, green: 0.12, blue: 0.30),
                glow: Color(red: 1.00, green: 0.96, blue: 0.72)
            )
        case .meadow:
            return PlanetPulsePalette(
                backgroundStart: Color(red: 0.86, green: 0.96, blue: 0.90),
                backgroundEnd: Color(red: 0.97, green: 0.94, blue: 0.83),
                secondary: Color(red: 0.22, green: 0.39, blue: 0.32),
                accent: Color(red: 0.16, green: 0.44, blue: 0.35),
                glow: Color(red: 1.00, green: 1.00, blue: 0.94)
            )
        case .lavender:
            return PlanetPulsePalette(
                backgroundStart: Color(red: 0.91, green: 0.88, blue: 0.97),
                backgroundEnd: Color(red: 0.98, green: 0.87, blue: 0.91),
                secondary: Color(red: 0.36, green: 0.27, blue: 0.44),
                accent: Color(red: 0.43, green: 0.29, blue: 0.61),
                glow: Color(red: 1.00, green: 0.96, blue: 1.00)
            )
        case .softSky:
            return PlanetPulsePalette(
                backgroundStart: Color(red: 0.86, green: 0.94, blue: 0.97),
                backgroundEnd: Color(red: 0.98, green: 0.95, blue: 0.87),
                secondary: Color(red: 0.22, green: 0.36, blue: 0.43),
                accent: Color(red: 0.15, green: 0.44, blue: 0.55),
                glow: Color(red: 0.98, green: 1.00, blue: 1.00)
            )
        }
    }
}

@available(iOS 17.0, *)
private extension Image {
    @ViewBuilder
    func planetPulseWidgetFullColor() -> some View {
        if #available(iOSApplicationExtension 18.0, *) {
            widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}

@available(iOS 17.0, *)
struct PlanetPulsePreviews: PreviewProvider {
    static var previews: some View {
        Group {
            PlanetPulseView(entry: informedEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            PlanetPulseView(entry: informedEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)

            PlanetPulseView(entry: .preview)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.sizeCategory, .accessibilityLarge)
        }
    }

    private static var informedEntry: PlanetPulseEntry {
        let card = PlanetPulseContent.fallbackInsight
        let destinationURL = try? PlanetPulseURLBuilder(scheme: "ecosia").url(for: card.destination)
        return PlanetPulseEntry(
            date: Date(),
            mode: .stayInformed,
            appearance: .ecosiaClassic,
            card: card,
            destinationURL: destinationURL
        )
    }
}
