// Wayfinder

import SwiftUI

struct RenameView: View {
    @Binding var isPresented: Bool
    var oldName: String
    var invalidNames: [String]
    var saveAction: ((String)->Void)
    
    @State var newName: String = ""
    
    var body: some View {
        VStack {
            HStack { Text("Rename **\(oldName)** to..."); Spacer() }
            TextField("New name", text: $newName)
            let nameIsInvalid = invalidNames.contains(newName)
            if nameIsInvalid {
                Text("A '\(newName)' view already exists")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            Button {
               saveAction(newName)
               isPresented = false
            } label: {
                Text("Rename")
                    .disabled(nameIsInvalid)
            }
        }
        .padding()
    }
}

struct RenameView_Previews: PreviewProvider {
    static var previews: some View {
        RenameView(isPresented: .constant(true), oldName: "Work", invalidNames: [], saveAction: {_ in})
    }
}
