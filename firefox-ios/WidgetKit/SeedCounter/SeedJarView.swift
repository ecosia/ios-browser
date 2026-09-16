// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI

/// The seed jar illustration driven entirely by `levelProgress` (0…1).
/// Draw the jar as SwiftUI shapes so the fill can be animated by `levelProgress`.
/// The frame is always 80 × 82 pt as measured in the design spec.
struct SeedJarView: View {
    let levelProgress: Double

    @Environment(\.colorScheme) private var colorScheme

    private var clamped: Double { max(0, min(1, levelProgress)) }

    // MARK: Colors

    private var bodyFill: Color {
        colorScheme == .dark ? Color(uiColor: EcosiaColor.Gray80) : .white
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color(uiColor: EcosiaColor.Gray60) : Color(uiColor: EcosiaColor.Gray30)
    }

    // MARK: Layout constants (points, from spec)

    private let lidHeight: CGFloat = 11
    private let lidInset: CGFloat = 8
    private let bodyTopOffset: CGFloat = 9

    // MARK: Body

    var body: some View {
        ZStack(alignment: .top) {
            lidView
            bodyContainerView.padding(.top, bodyTopOffset)
        }
    }

    // MARK: Lid

    private var lidView: some View {
        Color(uiColor: EcosiaColor.Grellow100)
            .frame(height: lidHeight)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.horizontal, lidInset)
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
            topLeadingRadius: 11, bottomLeadingRadius: 26,
            bottomTrailingRadius: 26, topTrailingRadius: 11
        )
        return ZStack {
            shape.fill(bodyFill)
            interiorView(bh: bh, bw: bw, fh: fh).clipShape(shape)
            shape.stroke(strokeColor, lineWidth: 2.5)
        }
    }

    private func jarWithRoundedRect(bh: CGFloat, bw: CGFloat, fh: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18)
        return ZStack {
            shape.fill(bodyFill)
            interiorView(bh: bh, bw: bw, fh: fh).clipShape(shape)
            shape.stroke(strokeColor, lineWidth: 2.5)
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

            // Empty-jar ghost seed — centred on the floor (spec: left:31, bottom:4, w:18).
            if clamped == 0 {
                seedView(w: 18, rot: 0, op: 0.22)
                    .offset(x: 31, y: bh - 4 - 18)
            }

            // Air seeds — 2 seeds drifting above the fill.
            // Shown only when 0.3 ≤ progress ≤ 0.9 (spec rule).
            if (0.3...0.9) ~= clamped {
                // left:16, top:6, w:14
                seedView(w: 14, rot: -24, op: 0.5).offset(x: 16, y: 6)
                // left:42, top:17, w:12
                seedView(w: 12, rot: 30, op: 0.35).offset(x: 42, y: 17)
            }

            // Fill seeds — positioned relative to the fill's top edge.
            // `t` is the y-coordinate of the fill's top in body-local space.
            if clamped > 0 {
                let t = bh - fh
                if clamped >= 0.3 {
                    // 6 seeds (rotations: −16 / 8 / −30 / 22 / 40 / −12)
                    seedView(w: 16, rot: -16, op: 1.0).offset(x: 1,  y: t - 7)
                    seedView(w: 16, rot:   8, op: 1.0).offset(x: 19, y: t - 10)
                    seedView(w: 16, rot: -30, op: 1.0).offset(x: 36, y: t - 7)
                    seedView(w: 16, rot:  22, op: 1.0).offset(x: 53, y: t - 9)
                    seedView(w: 15, rot:  40, op: 0.55).offset(x: 11, y: t + 11)
                    seedView(w: 15, rot: -12, op: 0.55).offset(x: 44, y: t + 14)
                } else {
                    // 3 seeds (rotations: −16 / 12 / −26)
                    seedView(w: 16, rot: -16, op: 1.0).offset(x: 4,  y: t - 7)
                    seedView(w: 16, rot:  12, op: 1.0).offset(x: 24, y: t - 10)
                    seedView(w: 16, rot: -26, op: 1.0).offset(x: 46, y: t - 7)
                }
            }
        }
    }

    // MARK: Seed helper

    private func seedView(w: CGFloat, rot: Double, op: Double) -> some View {
        Image("seed")
            .resizable()
            .frame(width: w, height: w)
            .rotationEffect(.degrees(rot))
            .opacity(op)
    }
}

// MARK: - Preview

struct SeedJarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SeedJarView(levelProgress: 0.62)
                .frame(width: 80, height: 82)
                .previewDisplayName("62 %")

            SeedJarView(levelProgress: 0.22)
                .frame(width: 80, height: 82)
                .previewDisplayName("22 %")

            SeedJarView(levelProgress: 0)
                .frame(width: 80, height: 82)
                .previewDisplayName("empty")

            SeedJarView(levelProgress: 1)
                .frame(width: 80, height: 82)
                .previewDisplayName("full")
        }
        .background(Color.white)
    }
}
#endif
