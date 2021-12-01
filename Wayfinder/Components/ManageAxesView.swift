// Wayfinder

import SwiftUI

struct ManageAxesView: View {
    
    @ObservedObject var dataStore: DataStore
    
    @State private var newAxis: String = ""
    @State private var axisIndexToRename: Int?
    @State private var isAxisRenamePresented: Bool = false
    @State private var errorMessage: ErrorMessage?
    
    var body: some View {
        Text("Manage views").font(.title).padding([.top])
        List {
            ForEach(dataStore.axisNames.indices, id: \.self) { index in
                Text(dataStore.axisNames[index])
                    // TODO this causes the "disabling recursion trigger logging" message
                    .contextMenu {
                        Button {
                            axisIndexToRename = index
                            isAxisRenamePresented = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                    }
            }
            .onDelete { indices in
                let axesToDelete = indices.map{ dataStore.axisNames[$0] }
                dataStore.delete(axes: axesToDelete) { error in
                    if let error = error {
                        dataStore.axisNames.append(contentsOf: axesToDelete)
                        dataStore.axisNames.sort(by: <)
                        errorMessage = ErrorMessage(title: "Can't delete view", message: "\(error)")
                    }
                }
                withAnimation {
                    dataStore.axisNames.remove(atOffsets: indices)
                }
            }
            HStack {
                TextField("New View", text: $newAxis)
                Button(action: {
                    dataStore.add(axis: newAxis) { error in
                        if let error = error {
                            errorMessage = ErrorMessage(title: "Can't add view", message: "\(error)")
                        }
                    }
                    withAnimation {
                        let insertionIndex = dataStore.axisNames.insertionIndex(of: newAxis, using: >)
                        dataStore.axisNames.insert(newAxis, at: insertionIndex)
                        newAxis = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newAxis.isEmpty)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
    }
}

struct ManageAxesView_Previews: PreviewProvider {
    static var previews: some View {
        ManageAxesView(
            dataStore: DataStore.createExample()
        )
    }
}
