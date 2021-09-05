// Wayfinder

import SwiftUI

struct EditViewSheet: View {
    
    @ObservedObject var dbData: DbData
    let dismissAction: (() -> Void)
    let addAction: (() -> Void)
    
    @State private var newReflectionData = Reflection.Data()
    
    func saveAction() -> Void {
        // The default id is 0, and will be re-assigned when it is inserted into the database
        // After the data is inserted into the database, that insertion id needs to be pushed back to the list in memory
        // To find this reflection in memory, we give it a unique id
        newReflectionData.id = dbData.nextUniqueReflectionId()
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
