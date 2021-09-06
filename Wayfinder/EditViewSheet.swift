// Wayfinder

import SwiftUI

/// A wrapped EditView intended to be embedded in a sheet.
/// Includes "Dismiss" and "Add" buttons that stop presenting the sheet when pressed.
/// Pressing the "Add" button will additionally save the new reflection to the database.
/// Optionally include additional actions to be called on the "Dismiss" and "Add" button presses.
struct EditViewSheet: View {
    
    @ObservedObject var dbData: DbData
    @Binding var isPresented: Bool
    var dismissAction: (() -> Void) = {}
    var addAction: (() -> Void) = {}
    
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
            EditView(data: $newReflectionData, existingNames: dbData.uniqueReflectionNames)
                .navigationBarItems(
                    leading: Button("Dismiss") {
                        dismissAction()
                        isPresented = false
                    },
                    trailing: Button("Add") {
                        saveAction()
                        addAction()
                        isPresented = false
                    }
                )
        }
    }
}

struct EditViewSheet_Previews: PreviewProvider {
    static var previews: some View {
        EditViewSheet(dbData: DbData(), isPresented: .constant(true))
    }
}
