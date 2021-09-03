// Wayfinder

import SwiftUI

struct EditViewSheet: View {
    
    @ObservedObject var dbData: DbData
    let dismissAction: (() -> Void)
    let addAction: (() -> Void)
    
    @State private var newReflectionData = Reflection.Data()
    
    func saveAction() -> Void {
        dbData.saveReflection(reflection: newReflectionData.reflection)
        newReflectionData = Reflection.Data()
    }
    
    var body: some View {
        NavigationView {
            EditView(data: $newReflectionData)
                .navigationBarItems(
                    leading: Button("Dismiss") {
                        dismissAction()
                    },
                    trailing: Button("Add") {
                        saveAction()
                        addAction()
                    }
                )
        }
    }
}

struct EditViewSheet_Previews: PreviewProvider {
    static var previews: some View {
        EditViewSheet(dbData: DbData(), dismissAction: {}, addAction: {})
    }
}
