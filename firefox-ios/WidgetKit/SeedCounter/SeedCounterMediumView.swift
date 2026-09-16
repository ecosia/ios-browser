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

/// 4×2 · systemMedium.
///
/// Two columns: the jar on the left, and on the right the count pinned to the top with the
/// progress group pinned to the bottom. That distribution puts the jar's rim level with the
/// level capsule, which is what makes the two columns read as one object rather than two.
struct SeedCounterMediumView: View {
    let entry: SeedCounterProvider.Entry

    @SwiftUI.Environment(\.colorScheme) private var colorScheme

    private var palette: SeedWidgetPalette { SeedWidgetPalette(colorScheme: colorScheme) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            SeedJarView(levelProgress: entry.displayProgress, metrics: .medium)
                .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 0) {
                countRow
                Spacer(minLength: 8)
                bottomGroup
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(palette.background)
    }

    // MARK: Count

    private var countRow: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(entry.countText)
                    .font(.system(size: 40, weight: .bold))
                    .kerning(-0.02 * 40)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(palette.primaryText)
                    .widgetAccentableCompat()

                Text(String.localized(.seedsWidgetLabel))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(palette.secondaryText)
            }

            Spacer(minLength: 0)

            if entry.isSignedIn {
                SeedWidgetAvatar(image: entry.avatarImage, size: 26)
            }
        }
    }

    // MARK: Bottom group

    @ViewBuilder
    private var bottomGroup: some View {
        if entry.isSignedIn {
            progressGroup
        } else {
            signUpGroup
        }
    }

    private var progressGroup: some View {
        VStack(alignment: .leading, spacing: 7) {
            SeedWidgetLevelCapsule(text: entry.capsuleText, palette: palette)

            SeedWidgetProgressBar(progress: entry.displayProgress, height: 6, palette: palette)

            Text(entry.mediumCaption)
                .font(.system(size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundColor(palette.secondaryText)
        }
    }

    /// Logged out: no level data exists, so the capsule, bar, caption and avatar all go and the
    /// bottom group becomes the acquisition moment.
    private var signUpGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String.localized(.signUpToKeepSeedsAndLevelUp))
                .font(.system(size: 12))
                .lineSpacing(12 * 0.4)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(palette.secondaryText)

            SeedWidgetSignUpButton(palette: palette)
        }
    }
}

// MARK: - Preview

struct SeedCounterMediumView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SeedCounterMediumView(entry: .galleryPreview)
                .previewDisplayName("Progressing · light")

            SeedCounterMediumView(entry: .galleryPreview)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Progressing · dark")

            SeedCounterMediumView(
                entry: SeedCounterEntry(
                    date: .now,
                    seedCount: 0,
                    levelProgress: 0,
                    isSignedIn: true,
                    currentLevel: 1,
                    levelNames: ["Ecocurious", "Green explorer", "Planet pal", "Seedling supporter"]
                )
            )
            .previewDisplayName("Empty · signed in")

            SeedCounterMediumView(
                entry: SeedCounterEntry(date: .now, seedCount: 3, levelProgress: 0.18, isSignedIn: false)
            )
            .previewDisplayName("Logged out")

            SeedCounterMediumView(entry: .placeholder)
                .previewDisplayName("Placeholder")
        }
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif
