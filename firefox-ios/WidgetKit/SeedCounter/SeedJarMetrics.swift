// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import CoreGraphics

/// One seed drawn inside the jar. All values are points, as measured in the design spec.
struct SeedPlacement {
    /// Leading offset inside the jar body.
    let x: CGFloat
    /// Vertical offset from the placement's own anchor: the body's top edge for air seeds,
    /// the fill's top edge for fill seeds, and the body's floor (measured upwards) for the
    /// resting seed of the empty state.
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let opacity: Double

    init(x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double = 0, opacity: Double = 1) {
        self.x = x
        self.y = y
        self.size = size
        self.rotation = rotation
        self.opacity = opacity
    }
}

/// Jar geometry per widget family. The jar is drawn with shapes rather than shipped as an asset
/// so its fill can be driven by the progress value; only the seed itself is an asset.
struct SeedJarMetrics {
    let width: CGFloat
    let height: CGFloat

    let lidHeight: CGFloat
    let lidInset: CGFloat
    let lidRadius: CGFloat

    let bodyTopOffset: CGFloat
    let strokeWidth: CGFloat
    let bodyTopRadius: CGFloat
    let bodyBottomRadius: CGFloat

    /// Seeds drifting above the fill, shown only between 0.3 and 0.9 progress.
    let airSeeds: [SeedPlacement]
    /// The full seed set riding on the fill's top edge, from 0.3 progress upwards.
    let fillSeeds: [SeedPlacement]
    /// The reduced set shown below 0.3 progress.
    let lowFillSeeds: [SeedPlacement]
    /// The single seed resting on the jar floor when progress is 0.
    let restingSeed: SeedPlacement

    // MARK: - Families

    /// 2×2 — matches the shipped small widget.
    static let small = SeedJarMetrics(
        width: 80,
        height: 82,
        lidHeight: 11,
        lidInset: 8,
        lidRadius: 5,
        bodyTopOffset: 9,
        strokeWidth: 2.5,
        bodyTopRadius: 11,
        bodyBottomRadius: 26,
        airSeeds: [
            SeedPlacement(x: 16, y: 6, size: 14, rotation: -24, opacity: 0.5),
            SeedPlacement(x: 42, y: 17, size: 12, rotation: 30, opacity: 0.35)
        ],
        fillSeeds: [
            SeedPlacement(x: 1, y: -7, size: 16, rotation: -16),
            SeedPlacement(x: 19, y: -10, size: 16, rotation: 8),
            SeedPlacement(x: 36, y: -7, size: 16, rotation: -30),
            SeedPlacement(x: 53, y: -9, size: 16, rotation: 22),
            SeedPlacement(x: 11, y: 11, size: 15, rotation: 40, opacity: 0.55),
            SeedPlacement(x: 44, y: 14, size: 15, rotation: -12, opacity: 0.55)
        ],
        lowFillSeeds: [
            SeedPlacement(x: 4, y: -7, size: 16, rotation: -16),
            SeedPlacement(x: 24, y: -10, size: 16, rotation: 12),
            SeedPlacement(x: 46, y: -7, size: 16, rotation: -26)
        ],
        restingSeed: SeedPlacement(x: 31, y: 4, size: 18, opacity: 0.22)
    )

    /// 4×2 — jar frame 84 × 104.
    static let medium = SeedJarMetrics(
        width: 84,
        height: 104,
        lidHeight: 11,
        lidInset: 9,
        lidRadius: 5,
        bodyTopOffset: 9,
        strokeWidth: 2.5,
        bodyTopRadius: 11,
        bodyBottomRadius: 26,
        airSeeds: [
            SeedPlacement(x: 18, y: 8, size: 15, rotation: -24, opacity: 0.5),
            SeedPlacement(x: 44, y: 20, size: 13, rotation: 30, opacity: 0.35)
        ],
        fillSeeds: [
            SeedPlacement(x: 2, y: -7, size: 17, rotation: -16),
            SeedPlacement(x: 20, y: -11, size: 17, rotation: 8),
            SeedPlacement(x: 38, y: -8, size: 17, rotation: -30),
            SeedPlacement(x: 56, y: -10, size: 17, rotation: 22),
            SeedPlacement(x: 11, y: 11, size: 16, rotation: 40, opacity: 0.55),
            SeedPlacement(x: 46, y: 14, size: 16, rotation: -12, opacity: 0.55)
        ],
        lowFillSeeds: [
            SeedPlacement(x: 4, y: -7, size: 17, rotation: -16),
            SeedPlacement(x: 24, y: -10, size: 17, rotation: 12),
            SeedPlacement(x: 46, y: -7, size: 17, rotation: -26)
        ],
        restingSeed: SeedPlacement(x: 31, y: 4, size: 18, opacity: 0.22)
    )

    /// 4×4 — jar frame 112 × 140.
    static let large = SeedJarMetrics.large(height: 140)

    /// 4×4 logged out — 8 pt shorter to make room for the sign-up band.
    static let largeLoggedOut = SeedJarMetrics.large(height: 132)

    private static func large(height: CGFloat) -> SeedJarMetrics {
        SeedJarMetrics(
            width: 112,
            height: height,
            lidHeight: 14,
            lidInset: 11,
            lidRadius: 6,
            bodyTopOffset: 12,
            strokeWidth: 3,
            bodyTopRadius: 14,
            bodyBottomRadius: 34,
            airSeeds: [
                SeedPlacement(x: 24, y: 9, size: 20, rotation: -24, opacity: 0.5),
                SeedPlacement(x: 62, y: 24, size: 17, rotation: 30, opacity: 0.35)
            ],
            fillSeeds: [
                SeedPlacement(x: 1, y: -10, size: 23, rotation: -16),
                SeedPlacement(x: 25, y: -15, size: 23, rotation: 8),
                SeedPlacement(x: 50, y: -11, size: 23, rotation: -30),
                SeedPlacement(x: 76, y: -14, size: 23, rotation: 22),
                SeedPlacement(x: 14, y: 16, size: 21, rotation: 40, opacity: 0.55),
                SeedPlacement(x: 62, y: 20, size: 21, rotation: -12, opacity: 0.55),
                SeedPlacement(x: 38, y: 34, size: 20, rotation: 16, opacity: 0.4)
            ],
            lowFillSeeds: [
                SeedPlacement(x: 4, y: -10, size: 23, rotation: -16),
                SeedPlacement(x: 36, y: -14, size: 23, rotation: 12),
                SeedPlacement(x: 68, y: -10, size: 23, rotation: -26)
            ],
            restingSeed: SeedPlacement(x: 44, y: 6, size: 22, opacity: 0.22)
        )
    }
}
#endif
