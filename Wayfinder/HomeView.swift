// Wayfinder

import SwiftUI

struct HomeView: View {
    @ObservedObject var dbData: DbData
    @Environment(\.scenePhase) private var scenePhase
    @State private var isNewReflectionPresented = false
    @State private var newReflectionData = Reflection.Data()
    func saveAction() -> Void {
        dbData.saveReflection(reflection: newReflectionData.reflection)
        newReflectionData = Reflection.Data()
    }
    var body: some View {
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
        }
        .sheet(isPresented: $isNewReflectionPresented) {
            NavigationView {
                EditView(data: $newReflectionData)
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(dbData: DbData())
    }
}
