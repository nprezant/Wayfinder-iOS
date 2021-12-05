// Wayfinder

import SwiftUI

struct ManageAxesView: View {
    
    @ObservedObject var dataStore: DataStore
    
    @State private var newAxis: String = ""
    @State private var axisIndexToRename: Int?
    @State private var isAxisRenamePresented: Bool = false
    @State private var errorMessage: ErrorMessage?
    
    var visibleAxes: [Axis] {
        dataStore.visibleAxes
    }
    
    var hiddenAxes: [Axis] {
        dataStore.hiddenAxes
    }
    
    var body: some View {
        Text("Manage views").font(.title).padding([.top])
        List {
            Section() {
                ForEach(visibleAxes.indices, id: \.self) { index in
                    Text(visibleAxes[index].name)
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
                    let axesToDelete = indices.map{ visibleAxes[$0] }
                    dataStore.delete(axes: axesToDelete.map{ $0.name }) { error in
                        if let error = error {
                            errorMessage = ErrorMessage(title: "Can't delete view", message: "\(error)")
                        }
                    }
                }
                HStack {
                    TextField("New View", text: $newAxis)
                    Button(action: {
                        withAnimation {
                            dataStore.add(axis: newAxis) { error in
                                if let error = error {
                                    errorMessage = ErrorMessage(title: "Can't add view", message: "\(error)")
                                }
                            }
                            newAxis = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newAxis.isEmpty)
                }
            }
            if !hiddenAxes.isEmpty {
                Section(header: Text("Hidden Views")) {
                    ForEach(hiddenAxes.indices, id: \.self) { index in
                        Text(hiddenAxes[index].name)
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
                }
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
