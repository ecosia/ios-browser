// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Kingfisher
import SVGKit
import Core

struct CompanyJoinedAlertView: View {
    var companyName: String
    var filename: String {
        colorScheme == .dark ? "lottie_confetti_dark" : "lottie_confetti_light"
    }
    @Binding var isPresented: Bool
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            LottieView(filename: filename,
                       shouldReduceMotion: reduceMotion)
            
            VStack(spacing: 20) {
                Text("Congratulations 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding([.top, .leading, .trailing])

                Text("Your searches are now\nplanting trees 🌳🌳🌳 for")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Text(companyName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()

                    if let imageUrl = imageUrl {
                        KFImage(imageUrl)
                            .setProcessor(SVGImgProcessor())
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 40)
                    }
                }

                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Let's search")
                        .padding()
                        .font(.system(size: 25, weight: .bold))
                        .background(.clear)
                        .foregroundColor(Color(.legacyTheme.ecosia.primaryButton))
                }
                .padding(.bottom)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 20)
            .padding()
            .scaleEffect(scale)
            .onAppear {
                if reduceMotion {
                    scale = 1.0
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 1)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

extension CompanyJoinedAlertView {
    
    var imageUrl: URL? {
        guard let company = User.shared.company else { return nil }
        let imageName = company.logoLight
        let baseURL = Core.Environment.current.urlProvider.companiesBase.absoluteString
        let finalURLString = baseURL + "/logos/" + imageName
        return URL(string: finalURLString)
    }
}
