// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI

/// The seed jar illustration driven entirely by `levelProgress` (0…1).
/// Draw the jar as SwiftUI shapes so the fill can be driven by `levelProgress`.
/// Geometry, seed sizes and seed positions come from `SeedJarMetrics` so the same component
/// serves all three widget families.
struct SeedJarView: View {
    let levelProgress: Double
    let metrics: SeedJarMetrics

    init(levelProgress: Double, metrics: SeedJarMetrics = .small) {
        self.levelProgress = levelProgress
        self.metrics = metrics
    }

    @Environment(\.colorScheme) private var colorScheme

    private var clamped: Double { max(0, min(1, levelProgress)) }

    // MARK: Colors

    private var bodyFill: Color {
        colorScheme == .dark ? Color(uiColor: EcosiaColor.Gray80) : .white
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color(uiColor: EcosiaColor.Gray60) : Color(uiColor: EcosiaColor.Gray30)
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            lidView
            bodyContainerView.padding(.top, metrics.bodyTopOffset)
        }
        .frame(width: metrics.width, height: metrics.height)
    }

    // MARK: Lid

    private var lidView: some View {
        Color(uiColor: EcosiaColor.Grellow100)
            .frame(height: metrics.lidHeight)
            .clipShape(RoundedRectangle(cornerRadius: metrics.lidRadius))
            .padding(.horizontal, metrics.lidInset)
    }

    // MARK: Body container

    @ViewBuilder
    private var bodyContainerView: some View {
        GeometryReader { geo in
            let bh = geo.size.height
            let bw = geo.size.width
            let fh = clamped * bh
            jarBody(bh: bh, bw: bw, fh: fh)
        }
    }

    @ViewBuilder
    private func jarBody(bh: CGFloat, bw: CGFloat, fh: CGFloat) -> some View {
        if #available(iOSApplicationExtension 16.0, *) {
            jarWithUnevenShape(bh: bh, bw: bw, fh: fh)
        } else {
            jarWithRoundedRect(bh: bh, bw: bw, fh: fh)
        }
    }

    @available(iOSApplicationExtension 16.0, *)
    private func jarWithUnevenShape(bh: CGFloat, bw: CGFloat, fh: CGFloat) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: metrics.bodyTopRadius, bottomLeadingRadius: metrics.bodyBottomRadius,
            bottomTrailingRadius: metrics.bodyBottomRadius, topTrailingRadius: metrics.bodyTopRadius
        )
        return ZStack {
            shape.fill(bodyFill)
            interiorView(bh: bh, bw: bw, fh: fh).clipShape(shape)
            shape.stroke(strokeColor, lineWidth: metrics.strokeWidth)
        }
    }

    private func jarWithRoundedRect(bh: CGFloat, bw: CGFloat, fh: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: (metrics.bodyTopRadius + metrics.bodyBottomRadius) / 2)
        return ZStack {
            shape.fill(bodyFill)
            interiorView(bh: bh, bw: bw, fh: fh).clipShape(shape)
            shape.stroke(strokeColor, lineWidth: metrics.strokeWidth)
        }
    }

    // MARK: Interior (fill + seeds)

    /// All interior content positioned in body-local coordinates.
    /// Using `.topLeading` + `.offset` replicates CSS absolute positioning inside the body div.
    @ViewBuilder
    private func interiorView(bh: CGFloat, bw: CGFloat, fh: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Sizing anchor so the ZStack fills the full body area.
            Color.clear.frame(width: bw, height: bh)

            // Seed fill — anchored to the bottom of the body.
            if clamped > 0 {
                Color(uiColor: EcosiaColor.Yellow40)
                    .frame(width: bw, height: fh)
                    .offset(y: bh - fh)
            }

            // Empty-jar resting seed, centred on the floor. Lifted in dark mode, where the
            // light opacity of the light theme disappears against the dark interior.
            if clamped == 0 {
                let seed = metrics.restingSeed
                seedView(seed, opacity: colorScheme == .dark ? max(seed.opacity, 0.3) : seed.opacity)
                    .offset(x: seed.x, y: bh - seed.y - seed.size)
            }

            // Air seeds drifting above the fill — nothing to sprinkle over a near-empty jar,
            // and no room above a nearly full one.
            if (0.3...0.9) ~= clamped {
                ForEach(Array(metrics.airSeeds.enumerated()), id: \.offset) { _, seed in
                    seedView(seed).offset(x: seed.x, y: seed.y)
                }
            }

            // Fill seeds ride on the fill's top edge, so they rise with the progress value.
            if clamped > 0 {
                let fillTop = bh - fh
                let seeds = clamped >= 0.3 ? metrics.fillSeeds : metrics.lowFillSeeds
                ForEach(Array(seeds.enumerated()), id: \.offset) { _, seed in
                    seedView(seed).offset(x: seed.x, y: fillTop + seed.y)
                }
            }
        }
    }

    // MARK: Seed helper

    private func seedView(_ seed: SeedPlacement, opacity: Double? = nil) -> some View {
        Image("seed")
            .resizable()
            .frame(width: seed.size, height: seed.size)
            .rotationEffect(.degrees(seed.rotation))
            .opacity(opacity ?? seed.opacity)
            // Decorative: the widget carries one combined accessibility label.
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

struct SeedJarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack(alignment: .bottom, spacing: 12) {
                SeedJarView(levelProgress: 0.62, metrics: .small)
                SeedJarView(levelProgress: 0.62, metrics: .medium)
                SeedJarView(levelProgress: 0.62, metrics: .large)
            }
            .previewDisplayName("62 % · all families")

            HStack(alignment: .bottom, spacing: 12) {
                SeedJarView(levelProgress: 0, metrics: .medium)
                SeedJarView(levelProgress: 0.18, metrics: .medium)
                SeedJarView(levelProgress: 0.95, metrics: .medium)
                SeedJarView(levelProgress: 1, metrics: .medium)
            }
            .previewDisplayName("4×2 · empty / low / high / full")
        }
        .padding()
        .background(Color.white)
        .previewLayout(.sizeThatFits)
    }
}
#endif
