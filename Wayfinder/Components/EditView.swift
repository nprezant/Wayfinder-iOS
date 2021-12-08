// Wayfinder

import SwiftUI

struct EditView: View {
    
    @ObservedObject var dataStore: DataStore
    @Binding var data: Reflection.Data
    
    @State private var newTag: String = ""
    @State private var oldName: String = ""
    @State private var tagIndexToRename: Int?
    @State private var isActivityRenamePresented: Bool = false
    @State private var isTagRenamePresented: Bool = false
    
    var body: some View {
        List {
            // TODO fix issue with tappable area too small
            Section() {
                let prompt = dataStore.activityNames.isEmpty ? "Create Activity" : "Choose Activity"
                NavigationLink(
                    destination: NamePicker($data.name, nameOptions: dataStore.activityNames, prompt: prompt)
                ) {
                    NamePickerField(name: data.name, prompt: prompt, font: .title2)
                        .contentShape(Rectangle())
                }
                // TODO this causes the "disabling recursion trigger logging" message
                .contextMenu {
                    Button {
                        oldName = data.name
                        isActivityRenamePresented = true
                    } label: {
                        Label("Rename All", systemImage: "pencil")
                    }
                }
            }
            
            Section() {
                Toggle("Flow state", isOn: $data.isFlowState)
                    .padding(.trailing, 5)
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                LabeledSlider(label: "Engagement", value: $data.engagement, range: 0...100)
                LabeledSlider(label: "Energy", value: $data.energy, range: -100...100)
            }
            .onTapGesture {
                self.endEditing()
            }
            
            Section() {
                DatePicker(
                    "Date",
                    selection: $data.date,
                    displayedComponents: [.date]
                )
                // Force a rebuild on date change; there is a bug that changes the short/medium style randomly otherwise
                // https://stackoverflow.com/questions/66090210/swiftui-datepicker-jumps-between-short-and-medium-date-formats-when-changing-the
                .id(data.date)
                HStack {
                    Text("View")
                    Spacer()
                    Menu(content: {
                        let axisNames = dataStore.visibleAxes.map{ $0.name }
                        Picker(selection: $data.axis, label: Text(data.axis)) {
                            ForEach(axisNames, id: \.self) { axis in
                                Text(axis)
                            }
                        }
                    }, label: {
                        Text(data.axis)
                    })
                }
            }
            Section(header: Text("Tags")) {
                ForEach(data.tags.indices, id: \.self) { index in
                    Text(data.tags[index])
                        // TODO this causes the "disabling recursion trigger logging" message
                        .contextMenu {
                            Button {
                                tagIndexToRename = index
                                isTagRenamePresented = true
                            } label: {
                                Label("Rename All", systemImage: "pencil")
                            }
                        }
                }
                .onDelete { indices in
                    data.tags.remove(atOffsets: indices)
                }
                // Remove from the list any tags that are already listed on this reflection
                var tagOptions = dataStore.allTagNames
                let _ = tagOptions.removeAll(where: {data.tags.contains($0)})
                NavigationLink(
                    destination: NamePicker($newTag, nameOptions: tagOptions, prompt: "Add Tag") {
                        withAnimation {
                            data.tags.append(newTag)
                            newTag = ""
                        }
                    }
                ) {
                    NamePickerField(name: newTag, prompt: "Add Tag")
                        .contentShape(Rectangle())
                }
            }
            Section(header: Text("Notes")) {
                // TODO no placeholder text available yet...
                TextEditor(text: $data.note)
                    .frame(height: 100)
            }
            // Still silly.
            // https://developer.apple.com/forums/thread/652080
            let _ = "\(oldName), \(tagIndexToRename ?? 1)"
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $isActivityRenamePresented) {
            NamePicker($data.name, nameOptions: dataStore.activityNames, prompt: "Rename all of '\(oldName)'", canCreate: true, parentIsPresenting: $isActivityRenamePresented) {
                dataStore.enqueueBatchRename(BatchRenameData(category: .activity, from: oldName, to: data.name))
                oldName = ""
            }
        }
        .sheet(isPresented: $isTagRenamePresented) {
            if tagIndexToRename != nil {
                let oldTag = data.tags[tagIndexToRename!]
                NamePicker($newTag, nameOptions: dataStore.allTagNames, prompt: "Rename all of '\(oldTag)'", canCreate: true, parentIsPresenting: $isTagRenamePresented) {
                    dataStore.enqueueBatchRename(BatchRenameData(category: .tag, from: oldTag, to: newTag))
                    data.tags[tagIndexToRename!] = newTag
                    newTag = ""
                }
            }
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(
            dataStore: DataStore.createExample(),
            data: .constant(Reflection.exampleData[0].data)
        )
    }
}
