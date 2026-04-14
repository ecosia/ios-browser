// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A real-time audio waveform visualization view that displays a scrolling bar graph
/// representing microphone input levels. Each bar's height corresponds to the
/// amplitude of a recent audio sample, creating a visual representation of
/// the user's voice while speaking.
final class AudioWaveformView: UIView {

    // MARK: - Properties

    private let barCount: Int
    private let barWidth: CGFloat
    private let barSpacing: CGFloat
    private let barColor: UIColor

    /// Ring buffer of audio levels (0.0 ... 1.0).
    private var levels: [CGFloat]
    private var currentIndex: Int = 0

    /// CAShapeLayer bars, reused for efficiency.
    private var barLayers: [CAShapeLayer] = []

    private let minimumBarHeight: CGFloat = 2

    // MARK: - Init

    init(barCount: Int, barWidth: CGFloat, barSpacing: CGFloat, barColor: UIColor) {
        self.barCount = barCount
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.barColor = barColor
        self.levels = Array(repeating: 0, count: barCount)
        super.init(frame: .zero)
        setupBars()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupBars() {
        for _ in 0..<barCount {
            let barLayer = CAShapeLayer()
            barLayer.fillColor = barColor.cgColor
            layer.addSublayer(barLayer)
            barLayers.append(barLayer)
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarFrames()
    }

    private func updateBarFrames() {
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalWidth) / 2
        let maxHeight = bounds.height

        for (index, barLayer) in barLayers.enumerated() {
            // Read from ring buffer, oldest first
            let levelIndex = (currentIndex + index) % barCount
            let level = levels[levelIndex]
            let barHeight = max(minimumBarHeight, level * maxHeight)

            let x = startX + CGFloat(index) * (barWidth + barSpacing)
            let y = (maxHeight - barHeight) / 2
            let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: barWidth / 2)
            barLayer.path = path.cgPath
        }
    }

    // MARK: - Public API

    /// Adds a new audio level sample (0.0 ... 1.0) and refreshes the visualization.
    func addLevel(_ level: CGFloat) {
        levels[currentIndex] = max(0, min(1, level))
        currentIndex = (currentIndex + 1) % barCount
        updateBarFrames()
    }

    /// Resets all bars to zero height.
    func reset() {
        levels = Array(repeating: 0, count: barCount)
        currentIndex = 0
        updateBarFrames()
    }
}
