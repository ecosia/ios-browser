// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var filename: String
    var shouldReduceMotion: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        var animationView = LottieAnimationView(name: filename)
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = shouldReduceMotion ? .playOnce : .loop
        animationView.animationSpeed = shouldReduceMotion ? 0 : 1.0

        if shouldReduceMotion {
            animationView = .init(frame: .zero)
        }
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if !shouldReduceMotion {
            animationView.play()
        }
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
