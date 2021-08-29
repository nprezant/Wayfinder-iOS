// Wayfinder

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                NavigationLink(destination: ReflectionView()) {
                    Text("Reflect")
                        .font(.system(size: 40))
                        .padding(EdgeInsets(
                                    top: 10, leading: 20,
                                    bottom: 10, trailing: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 40.0)
                                .stroke(lineWidth: 2.0)
                    )
                }
                Spacer()
                Text("Summary info")
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .padding(10)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
