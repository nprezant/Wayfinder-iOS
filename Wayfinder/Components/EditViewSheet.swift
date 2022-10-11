// Wayfinder

import SwiftUI

/// A wrapped EditView intended to be embedded in a sheet.
/// Includes "Dismiss" and "Add" buttons that stop presenting the sheet when pressed.
/// Pressing the "Add" button will additionally save the new reflection to the database.
/// Optionally include additional actions to be called on the "Dismiss" and "Add" button presses.
struct EditViewSheet: View {
    
    @ObservedObject var store: Store
    @Binding var isPresented: Bool
    @Binding var errorMessage: ErrorMessage?
    var dismissAction: (() -> Void) = {}
    var addAction: (() -> Void) = {}
    
    @State private var newReflectionData = Reflection.Data(axis: "To be overwritten")
    
    func saveAction() -> Void {
        store.add(reflection: newReflectionData.reflection) { result in
            switch result {
            case .failure(let error):
                errorMessage = ErrorMessage(title: "Save Error", message: "\(error)")
            case .success(_):
                break
            }
        }
    }
    
    var body: some View {
        NavigationView {
            EditView(
                store: store,
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
            newReflectionData = Reflection.Data(axis: store.activeAxis)
        })
    }
}

struct EditViewSheet_Previews: PreviewProvider {
    static var previews: some View {
        EditViewSheet(store: Store(), isPresented: .constant(true), errorMessage: .constant(nil))
    }
}
