// Wayfinder

import SwiftUI

struct ManageAxesView: View {
    
    @ObservedObject var store: Store
    @Binding var isPresented: Bool
    
    @State private var newAxis: String = ""
    
    @State private var visibleAxisIndexToRename: Int?
    @State private var hiddenAxisIndexToRename: Int?
    
    @State private var isVisibleAxisRenamePresented: Bool = false
    @State private var isHiddenAxisRenamePresented: Bool = false
    
    @State private var visibleAxisIndexToMerge: Int?
    @State private var axisNameToMergeInto: String = ""
    @State private var isVisibleAxisMergePresented: Bool = false
    @State private var shouldDoMerge: Bool = false
    
    @State private var errorMessage: ErrorMessage?
    
    var visibleAxes: [Axis] {
        store.visibleAxes
    }
    
    var hiddenAxes: [Axis] {
        store.hiddenAxes
    }
    
    var allAxisNames: [String] {
        (visibleAxes + hiddenAxes).map{ $0.name }
    }
    
    func rename(from oldName: String, to newName: String) {
        guard let oldData = (visibleAxes + hiddenAxes).first(where: { $0.name == oldName }) else {
            errorMessage = ErrorMessage(title: "Cannot rename view", message: "View with name '\(oldName)' cannot be found")
            return
        }
        let updated = Axis(id: oldData.id, name: newName, hidden: oldData.hidden)
        if oldName == store.activeAxis {
            store.activeAxis = newName
        }
        store.update(axis: updated) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Cannot rename view", message: "\(error)")
            }
        }
    }
    
    func merge() {
        if !shouldDoMerge { return }
        guard let index = visibleAxisIndexToMerge else { return }
        let axis = visibleAxes[index]
        let into = axisNameToMergeInto
        merge(axis: axis, into: into)
    }
    
    func merge(axis: Axis, into: String) {
        // Reset state variables
        axisNameToMergeInto = ""
        shouldDoMerge = false
        // Do the merge
        guard let mergeInto = (visibleAxes + hiddenAxes).first(where: { $0.name == into }) else {
            errorMessage = ErrorMessage(title: "Cannot merge views", message: "\(into) view not found")
            return
        }
        if visibleAxes.count == 1 && visibleAxes[0].name == axis.name {
            // TODO The hackiest of hacks. Need to figure out how to run code AFTER the sheet is dismissed, not while it is being dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                errorMessage = ErrorMessage(title: "", message: "Please leave at least one view visible")
            }
            return
        }
        if axis.name == store.activeAxis {
            store.activeAxis = mergeInto.name
        }
        store.merge(axis: axis, into: mergeInto) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Cannot merge views", message: "\(error)")
            }
        }
    }
    
    func addNewAxis() {
        if allAxisNames.contains(newAxis) { return }
        if newAxis == "" { return }
        let insertionIndex = visibleAxes.map{ $0.name }.insertionIndex(of: newAxis, using: >)
        withAnimation {
            store.visibleAxes.insert(Axis(id: 0, name: newAxis, hidden: false.intValue), at: insertionIndex)
        }
        store.add(axis: newAxis) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Cannot add view", message: "\(error)")
            }
        }
        newAxis = ""
    }
    
    var body: some View {
        VStack {
            Text("Manage views").font(.title).padding([.top])
            List {
                Section() {
                    ForEach(visibleAxes.indices, id: \.self) { index in
                        Button {
                            store.sync(withAxis: visibleAxes[index].name)
                            isPresented = false
                        } label: {
                            Text(visibleAxes[index].name)
                            // TODO this causes the "disabling recursion trigger logging" message
                            .contextMenu {
                                Button {
                                    visibleAxisIndexToRename = index
                                    isVisibleAxisRenamePresented = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button {
                                    visibleAxisIndexToMerge = index
                                    isVisibleAxisMergePresented = true
                                } label: {
                                    Label("Merge into...", systemImage: "arrow.triangle.merge")
                                }
                                Button {
                                    if visibleAxes.count == 1 {
                                        errorMessage = ErrorMessage(title: "", message: "Please leave at least one view visible")
                                    }
                                    else {
                                        let a = visibleAxes[index]
                                        withAnimation {
                                            store.visibleAxes.remove(at: index)
                                            store.hiddenAxes.append(a)
                                        }
                                        store.update(axis: Axis(id: a.id, name: a.name, hidden: true.intValue)) { error in
                                            if let error = error {
                                                errorMessage = ErrorMessage(title: "Cannot hide view", message: "\(error)")
                                            }
                                        }
                                    }
                                } label: {
                                    Label("Hide", systemImage: "arrow.down")
                                }
                            }
                        }
                    }
                    .onDelete { indices in
                        let axesToDelete = indices.map{ visibleAxes[$0].name }
                        if visibleAxes.count == axesToDelete.count {
                            errorMessage = ErrorMessage(title: "", message: "Please leave at least one view visible")
                        } else {
                            if axesToDelete.contains(store.activeAxis) {
                                if let notDeletedVisibleAxis = visibleAxes.first(where: { !axesToDelete.contains($0.name) }) {
                                    store.activeAxis = notDeletedVisibleAxis.name
                                }
                            }
                            store.delete(axes: axesToDelete) { error in
                                if let error = error {
                                    errorMessage = ErrorMessage(title: "Cannot delete view", message: "\(error)")
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("Add view...", text: $newAxis, onCommit: {
                            addNewAxis()
                        })
                        Button(action: {
                            addNewAxis()
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newAxis.isEmpty || (allAxisNames.contains(newAxis)))
                    }
                }
                if !hiddenAxes.isEmpty {
                    Section(header: Text("Archived Views")) {
                        ForEach(hiddenAxes.indices, id: \.self) { index in
                            Text(hiddenAxes[index].name)
                                // TODO this causes the "disabling recursion trigger logging" message
                                .contextMenu {
                                    Button {
                                        hiddenAxisIndexToRename = index
                                        isHiddenAxisRenamePresented = true
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    Button {
                                        let a = hiddenAxes[index]
                                        withAnimation {
                                            store.hiddenAxes.remove(at: index)
                                            store.visibleAxes.append(a)
                                        }
                                        store.update(axis: Axis(id: a.id, name: a.name, hidden: false.intValue)) { error in
                                            if let error = error {
                                                errorMessage = ErrorMessage(title: "Cannot show view", message: "\(error)")
                                            }
                                        }
                                    } label: {
                                        Label("Show", systemImage: "arrow.up")
                                    }
                                }
                        }
                    }
                }
                // https://developer.apple.com/forums/thread/652080
                let _ = "\(hiddenAxisIndexToRename ?? 1) \(visibleAxisIndexToRename ?? 1) \(visibleAxisIndexToMerge ?? 1)"
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
        .sheet(isPresented: $isVisibleAxisRenamePresented) {
            if let index = visibleAxisIndexToRename {
                RenameView(isPresented: $isVisibleAxisRenamePresented, oldName: visibleAxes[index].name, invalidNames: allAxisNames) { newName in
                    let a = visibleAxes[index]
                    rename(from: a.name, to: newName)
                }
                .dismissable(isPresented: $isVisibleAxisRenamePresented)
            }
        }
        .sheet(isPresented: $isVisibleAxisMergePresented, onDismiss: { merge() }) {
            if let index = visibleAxisIndexToMerge {
                let axisNameOptions = allAxisNames.filter{ $0 != visibleAxes[index].name } // Can't merge an axis into itself now can we
                NamePicker($axisNameToMergeInto, nameOptions: axisNameOptions, prompt: "Merge '\(visibleAxes[index].name)' into...", canCreate: false, parentIsPresenting: $isVisibleAxisMergePresented) {
                    shouldDoMerge = true
                }
                // TODO simplify name picker. Doesn't need to handle parent presentation.
            }
        }
        .sheet(isPresented: $isHiddenAxisRenamePresented) {
            if let index = hiddenAxisIndexToRename {
                RenameView(isPresented: $isHiddenAxisRenamePresented, oldName: hiddenAxes[index].name, invalidNames: allAxisNames) { newName in
                    let a = hiddenAxes[index]
                    rename(from: a.name, to: newName)
                }
                .dismissable(isPresented: $isHiddenAxisRenamePresented)
            }
        }
    }
}

struct ManageAxesView_Previews: PreviewProvider {
    static var previews: some View {
        ManageAxesView(
            store: Store.createExample(),
            isPresented: .constant(true)
        )
            .dismissable()
    }
}
