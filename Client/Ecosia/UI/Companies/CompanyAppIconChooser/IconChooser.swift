import SwiftUI

struct IconChooser: View {
    @EnvironmentObject var model: AppIconChooserModel

    var body: some View {
        let columns = Array(repeating: GridItem(.adaptive(minimum: 114, maximum: 1024),
                                                spacing: 16), count: 3)

        VStack {
            HStack {
                Text("Your app icon:")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                IconImage(icon: model.appIcon)
                    .frame(width: 114, height: 114)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AppIcon.allCases) { icon in
                        Button {
                            model.setAlternateAppIcon(icon: icon)
                        } label: {
                            IconImage(icon: icon)
                        }
                    }
                }
                .padding()
            }
        }
        .cornerRadius(12)
        .padding()
    }
}

struct IconChooser_Previews: PreviewProvider {
    static var previews: some View {
        IconChooser()
            .environmentObject(AppIconChooserModel())
    }
}
