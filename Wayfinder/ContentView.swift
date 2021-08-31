// Wayfinder

import SwiftUI

struct ContentView: View {
    @Binding var dbData: DbData
    @Environment(\.scenePhase) private var scenePhase
    @State private var isNewReflectionPresented = false
    @State private var newReflectionData = Reflection.Data()
    func saveAction() -> Void {
        dbData.saveReflection(reflection: newReflectionData.reflection)
        newReflectionData = Reflection.Data()
    }
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Button(action: {
                    isNewReflectionPresented = true
                }) {
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
        .sheet(isPresented: $isNewReflectionPresented) {
            NavigationView {
                ReflectionView(reflectionData: $newReflectionData)
                    .navigationBarItems(leading: Button("Dismiss") {
                        isNewReflectionPresented = false
                    }, trailing: Button("Add") {
                        saveAction()
                        isNewReflectionPresented = false
                    })
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dbData: .constant(DbData()))
    }
}
