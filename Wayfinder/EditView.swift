// Wayfinder

import SwiftUI

struct ReflectionSlider: View {
    let label: String
    @Binding var value: Int64
    var range: ClosedRange<Double>
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
            }
            HStack {
                Slider(
                    value: Binding<Double>(
                        get: { return Double(value) },
                        set: { value = Int64(truncating: $0 as NSNumber) }),
                    in: range,
                    step: 1
                )
                Text("\(value, specifier: "%+d%%")")
                    .frame(minWidth: 50)
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func endEditing() {
        UIApplication.shared.endEditing()
    }
}


struct EditView: View {
    
    @ObservedObject var dataStore: DataStore
    @Binding var data: Reflection.Data
    let existingReflections: [String]
    let existingTags: [String]
    
    @State var newTag: String = ""
    @State private var oldName: String = ""
    @State private var isRenamePresented: Bool = false
    
    var body: some View {
        List {
            // TODO fix issue with tappable area too small
            Section() {
                NavigationLink(
                    destination: NamePicker($data.name, nameOptions: existingReflections, prompt: "Choose Activity")
                ) {
                    NamePickerField(name: data.name, prompt: "Choose Activity", font: .title2)
                        .contentShape(Rectangle())
                }
                .contextMenu {
                    Button {
                        oldName = data.name
                        isRenamePresented = true
                    } label: {
                        Label("Rename All", systemImage: "pencil")
                    }
                }
            }
            
            Section() {
                Toggle("Flow state", isOn: $data.isFlowState)
                    .padding(.trailing, 5)
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                ReflectionSlider(label: "Engagement", value: $data.engagement, range: 0...100)
                ReflectionSlider(label: "Energy", value: $data.energy, range: -100...100)
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
            }
            Section() {
                ForEach(data.tags, id: \.self) { tagName in
                    Text(tagName)
                }
                .onDelete { indices in
                    data.tags.remove(atOffsets: indices)
                }
                // Include in the list options that have not yet been commited to the db
                let tagOptions = Array(Set((existingTags + data.tags).map{$0})).sorted(by: <)
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
            Section() {
                // TODO no placeholder text available yet...
                TextEditor(text: $data.note)
                    .frame(height: 100)
            }
            // Still silly.
            // https://developer.apple.com/forums/thread/652080
            Text("\(oldName)")
                .hidden()
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $isRenamePresented) {
            NamePicker($data.name, nameOptions: existingReflections, prompt: "Rename '\(oldName)'", canCreate: true, parentIsPresenting: $isRenamePresented) {
                dataStore.renameReflections(from: oldName, to: data.name)
            }
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(
            dataStore: DataStore.createExample(),
            data: .constant(Reflection.exampleData[0].data),
            existingReflections: DataStore.createExample().uniqueReflectionNames,
            existingTags: ["tag 1", "tag 2", "tag 3"]
        )
    }
}
