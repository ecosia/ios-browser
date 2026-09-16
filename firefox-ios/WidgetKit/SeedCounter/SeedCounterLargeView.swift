// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit
// Ecosia: import Ecosia so that String.localized and EcosiaColor are available.
// Note: importing Ecosia pulls a second `Environment` into scope; SwiftUI property wrappers
// must therefore be qualified as @SwiftUI.Environment to avoid ambiguity.
import Ecosia

/// 4×4 · systemLarge.
///
/// Four stacked bands — header, hero, progress and ladder. The ladder is the reason this size
/// exists: it turns a number into a collection. Logged out it becomes a distinct layout rather
/// than a degraded one, with a sign-up band in place of the progress band and a teaser ladder
/// of locked levels.
///
/// The band margins are tight on purpose: the four bands plus padding fill the canvas with
/// roughly a point of headroom, so nothing here should gain extra space.
struct SeedCounterLargeView: View {
    let entry: SeedCounterProvider.Entry

    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    private var palette: SeedWidgetPalette { SeedWidgetPalette(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            hero
            if entry.isSignedIn {
                progressBand
                divider
            } else {
                signUpBand
            }
            ladderLabel
            ladder
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .widgetBackground(palette.background)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            if entry.isSignedIn {
                SeedWidgetAvatar(image: entry.avatarImage, size: 22)
            }

            Text(String.localized(.yourSeeds))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(palette.secondaryText)

            Spacer(minLength: 8)

            if entry.isSignedIn {
                SeedWidgetLevelCapsule(text: entry.capsuleText, palette: palette)
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.countText)
                    .font(.system(size: 54, weight: .bold))
                    .kerning(-0.03 * 54)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(palette.primaryText)
                    .widgetAccentableCompat()

                Text(String.localized(.seedsCollectedWidgetLabel))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(palette.secondaryText)
            }
            // Lifts the count's baseline above the jar's foot.
            .padding(.bottom, 14)

            SeedJarView(
                levelProgress: entry.displayProgress,
                metrics: entry.isSignedIn ? .large : .largeLoggedOut
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, entry.isSignedIn ? 12 : 10)
    }

    // MARK: Progress band

    private var progressBand: some View {
        VStack(spacing: 7) {
            SeedWidgetProgressBar(progress: entry.displayProgress, height: 7, palette: palette)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.largeLeadingCaption)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundColor(palette.secondaryText)

                Spacer(minLength: 0)

                // The reward side carries the emphasis colour.
                if let trailing = entry.largeTrailingCaption {
                    Text(trailing)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .foregroundColor(palette.primaryText)
                }
            }
        }
        .padding(.top, 14)
    }

    /// Logged out: replaces the progress band. Its own separation makes the divider redundant.
    private var signUpBand: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String.localized(.signUpToKeepSeedsAndUnlockLevels))
                .font(.system(size: 12))
                .lineLimit(2)
                // The four bands fill the canvas with barely a point to spare, so a longer
                // localization scales down rather than pushing the ladder off the card.
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(palette.secondaryText)

            SeedWidgetSignUpButton(palette: palette)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.stroke)
            .frame(height: 1)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    // MARK: Ladder

    private var ladderLabel: some View {
        Text(entry.ladderLabel)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(palette.secondaryText)
            .padding(.top, entry.isSignedIn ? 0 : 14)
            .padding(.bottom, entry.isSignedIn ? 10 : 6)
    }

    @ViewBuilder
    private var ladder: some View {
        if entry.isPlaceholder {
            spacedRow(count: SeedLevelLadder.visibleRungCount) { _ in
                SeedWidgetSkeletonBadge(palette: palette)
            }
        } else {
            let rungs = entry.ladderRungs
            spacedRow(count: rungs.count) { index in
                SeedWidgetLevelBadge(rung: rungs[index], palette: palette)
            }
        }
    }

    /// Four fixed-width columns spread across the card, matching the spec's space-between row.
    private func spacedRow<Content: View>(
        count: Int,
        @ViewBuilder content: @escaping (Int) -> Content
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                content(index)
                if index < count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

struct SeedCounterLargeView_Previews: PreviewProvider {
    private static let levelNames = [
        "Ecocurious", "Green explorer", "Planet pal", "Seedling supporter",
        "Biodiversity bestie", "Forest friend", "Wildlife protector", "Eco explorer"
    ]

    static var previews: some View {
        Group {
            SeedCounterLargeView(entry: .galleryPreview)
                .previewDisplayName("Progressing · light")

            SeedCounterLargeView(entry: .galleryPreview)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Progressing · dark")

            SeedCounterLargeView(
                entry: SeedCounterEntry(
                    date: .now,
                    seedCount: 0,
                    levelProgress: 0,
                    isSignedIn: true,
                    currentLevel: 1,
                    levelNames: levelNames
                )
            )
            .previewDisplayName("Empty · signed in")

            SeedCounterLargeView(
                entry: SeedCounterEntry(
                    date: .now,
                    seedCount: 3,
                    levelProgress: 0.18,
                    isSignedIn: false,
                    levelNames: levelNames
                )
            )
            .previewDisplayName("Logged out · teaser ladder")

            SeedCounterLargeView(entry: .placeholder)
                .previewDisplayName("Placeholder")
        }
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
#endif
