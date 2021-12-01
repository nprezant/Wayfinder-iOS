// Wayfinder

import SwiftUI

/// A wrapped EditView intended to be embedded in a sheet.
/// Includes "Dismiss" and "Add" buttons that stop presenting the sheet when pressed.
/// Pressing the "Add" button will additionally save the new reflection to the database.
/// Optionally include additional actions to be called on the "Dismiss" and "Add" button presses.
struct EditViewSheet: View {
    
    @ObservedObject var dataStore: DataStore
    @Binding var isPresented: Bool
    @Binding var errorMessage: ErrorMessage?
    var dismissAction: (() -> Void) = {}
    var addAction: (() -> Void) = {}
    
    @State private var newReflectionData = Reflection.Data()
    
    func saveAction() -> Void {
        dataStore.add(reflection: newReflectionData.reflection) { result in
            switch result {
            case .failure(let error):
                errorMessage = ErrorMessage(title: "Save Error", message: "\(error)")
            case .success(_):
                break
            }
        }
        newReflectionData = Reflection.Data(axis: dataStore.activeAxis)
    }
    
    var body: some View {
        NavigationView {
            EditView(
                dataStore: dataStore,
                data: $newReflectionData
            )
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
        .onAppear(perform: {
            newReflectionData = Reflection.Data(axis: dataStore.activeAxis)
        })
    }
}

struct EditViewSheet_Previews: PreviewProvider {
    static var previews: some View {
        EditViewSheet(dataStore: DataStore(), isPresented: .constant(true), errorMessage: .constant(nil))
    }
}
