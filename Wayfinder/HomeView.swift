// Wayfinder

import SwiftUI

struct HomeView: View {
    @Binding var dbData: DbData
    @Environment(\.scenePhase) private var scenePhase
    @State private var isNewReflectionPresented = false
    @State private var newReflectionData = Reflection.Data()
    func saveAction() -> Void {
        dbData.saveReflection(reflection: newReflectionData.reflection)
        newReflectionData = Reflection.Data()
    }
    var body: some View {
        GeometryReader {geometry in
            VStack {
                Spacer()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.33, alignment: .center)
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
            }
        }
        .sheet(isPresented: $isNewReflectionPresented) {
            NavigationView {
                EditView(reflectionData: $newReflectionData)
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
        HomeView(dbData: .constant(DbData()))
    }
}
