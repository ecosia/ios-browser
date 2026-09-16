// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI

/// The colour pairs the seed widgets are drawn with.
///
/// Widget extensions render outside the app's theme manager, so the palette resolves the
/// light/dark pair from the environment's colour scheme instead of `EcosiaThemeable`.
/// The yellow and the grellow deliberately do not flip between modes — they carry the brand
/// and hold contrast on both surfaces.
struct SeedWidgetPalette {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    /// Widget canvas.
    var background: Color { isDark ? Color(uiColor: EcosiaColor.Gray90) : Color(uiColor: EcosiaColor.Gray10) }
    /// Counts, capsule text, the emphasised half of the 4×4 caption row.
    var primaryText: Color { isDark ? .white : Color(uiColor: EcosiaColor.Gray70) }
    /// Labels and captions.
    var secondaryText: Color { isDark ? Color(uiColor: EcosiaColor.Gray30) : Color(uiColor: EcosiaColor.Gray50) }
    /// Bar track, divider, jar and badge strokes.
    var stroke: Color { isDark ? Color(uiColor: EcosiaColor.Gray60) : Color(uiColor: EcosiaColor.Gray30) }
    /// Jar interior and unlocked badge fill.
    var surface: Color { isDark ? Color(uiColor: EcosiaColor.Gray80) : .white }
    /// Locked badge fill.
    var mutedSurface: Color { isDark ? Color(uiColor: EcosiaColor.Gray80) : Color(uiColor: EcosiaColor.Gray20) }
    /// Seed fill, level capsule, current badge, progress bar fill.
    var brand: Color { Color(uiColor: EcosiaColor.Yellow40) }
    /// Jar lid and sign-up button.
    var accent: Color { Color(uiColor: EcosiaColor.Grellow100) }
    /// Text drawn on top of `brand` or `accent`, identical in both modes.
    var onBrandText: Color { Color(uiColor: EcosiaColor.Gray70) }
}

// MARK: - Level capsule

/// "Level {n} · {name}". Hugs its content and truncates the level name, never the number —
/// tail truncation keeps the leading number intact.
struct SeedWidgetLevelCapsule: View {
    let text: String
    let palette: SeedWidgetPalette

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundColor(palette.onBrandText)
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .background(Capsule().fill(palette.brand))
    }
}

// MARK: - Progress bar

/// The linear restatement of the jar fill. It reads the same value as the jar and must never
/// disagree with it, so both are driven by the same `progress`.
struct SeedWidgetProgressBar: View {
    let progress: Double
    let height: CGFloat
    let palette: SeedWidgetPalette

    private var clamped: Double { max(0, min(1, progress)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.stroke)
                if clamped > 0 {
                    Capsule()
                        .fill(palette.brand)
                        .frame(width: geo.size.width * clamped)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Sign-up button

/// A visual affordance only — the whole widget is the tap target.
struct SeedWidgetSignUpButton: View {
    let palette: SeedWidgetPalette

    var body: some View {
        Text(String.localized(.signUp))
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .foregroundColor(palette.onBrandText)
            .padding(.horizontal, 16)
            .frame(height: 30)
            .background(Capsule().fill(palette.accent))
    }
}

// MARK: - Avatar

/// The account avatar. Omitted entirely when there is no image — never drawn as an empty ring.
struct SeedWidgetAvatar: View {
    let image: UIImage?
    let size: CGFloat

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                // Decorative: the widget carries one combined accessibility label.
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Level badge

/// One rung of the 4×4 ladder. The current badge is the only solid one and the only one with a
/// bold label — that is what makes "you are here" readable at a glance.
struct SeedWidgetLevelBadge: View {
    let rung: SeedLevelLadder.Rung
    let palette: SeedWidgetPalette

    private var labelColor: Color {
        rung.state == .locked ? palette.secondaryText : palette.primaryText
    }

    var body: some View {
        VStack(spacing: 5) {
            circle
            Text(rung.name)
                .font(.system(size: 10, weight: rung.state == .current ? .bold : .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .foregroundColor(labelColor)
        }
        .frame(width: 72)
    }

    @ViewBuilder
    private var circle: some View {
        switch rung.state {
        case .unlocked:
            ZStack {
                Circle().fill(palette.surface)
                Circle().strokeBorder(palette.stroke, lineWidth: 1.5)
                seedGlyph(size: 28)
            }
            .frame(width: 52, height: 52)
        case .current:
            ZStack {
                Circle().fill(palette.brand)
                seedGlyph(size: 32)
            }
            .frame(width: 52, height: 52)
        case .locked:
            ZStack {
                Circle().fill(palette.mutedSurface)
                Circle().strokeBorder(palette.stroke, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                Image(systemName: "lock")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.secondaryText)
                    .frame(width: 18, height: 18)
                    // Decorative: the widget carries one combined accessibility label.
                    .accessibilityHidden(true)
            }
            .frame(width: 52, height: 52)
        }
    }

    private func seedGlyph(size: CGFloat) -> some View {
        Image("seed")
            .resizable()
            .frame(width: size, height: size)
            // Decorative: the widget carries one combined accessibility label.
            .accessibilityHidden(true)
    }
}

/// Redacted stand-in for a badge while WidgetKit renders the placeholder — no data access.
struct SeedWidgetSkeletonBadge: View {
    let palette: SeedWidgetPalette

    var body: some View {
        Circle()
            .fill(palette.mutedSurface)
            .frame(width: 52, height: 52)
            .frame(width: 72)
    }
}
#endif
