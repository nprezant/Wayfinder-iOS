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
                            Button {
                                axisIndexToRename = index
                                isAxisRenamePresented = true
                            } label: {
                                Label("Merge with...", systemImage: "arrow.triangle.merge")
                            }
                            Button {
                                if visibleAxes.count == 1 {
                                    errorMessage = ErrorMessage(title: "", message: "Please leave at least one view visible")
                                }
                                else {
                                    let a = visibleAxes[index]
                                    dataStore.update(axis: Axis(id: a.id, name: a.name, hidden: true.intValue)) { error in
                                        if let error = error {
                                            errorMessage = ErrorMessage(title: "Can't hide view", message: "\(error)")
                                        }
                                    }
                                }
                            } label: {
                                Label("Hide", systemImage: "trash")
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
                                Button {
                                    let a = hiddenAxes[index]
                                    dataStore.update(axis: Axis(id: a.id, name: a.name, hidden: false.intValue)) { error in
                                        if let error = error {
                                            errorMessage = ErrorMessage(title: "Can't show view", message: "\(error)")
                                        }
                                    }
                                } label: {
                                    Label("Show", systemImage: "arrow.up")
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
