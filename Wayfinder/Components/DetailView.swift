// Wayfinder

import SwiftUI

struct DetailView: View {
    
    @ObservedObject var dataStore: DataStore
    @Binding var reflection: Reflection
    let saveAction: ((Reflection) -> Void)
    var parentIsPresenting: Binding<Bool>? = nil // If supplied (e.g. when using in a sheet) additional header text and buttons are displayed that are otherwise handled by the navigation view
    
    @State private var data: Reflection.Data = Reflection.Data(axis: "To be overwritten")
    @State private var isPresented = false
    
    func editAction() {
        isPresented = true
        data = reflection.data
    }
    
    var body: some View {
        if parentIsPresenting != nil {
            HStack {
                Button("Cancel") { parentIsPresenting?.wrappedValue = false }
                Spacer()
                Button("Edit") { editAction() }
            }
            .padding([.top, .leading, .trailing])
            HStack {
                Text(reflection.name.isEmpty ? "Activity Name" : reflection.name)
                    .font(.title.bold())
                Spacer()
            }
            .padding()
        }
        List {
            Section() {
                HStack {
                    Label("Flow State?", systemImage: "wind")
                    Spacer()
                    Image(systemName: reflection.isFlowState.boolValue ? "checkmark.circle.fill" : "checkmark.circle").foregroundColor(.blue)
                }
                HStack {
                    Label("Engagement", systemImage: "sparkles")
                    Spacer()
                    Text("\(reflection.engagement)%")
                }
                HStack {
                    Label("Energy", systemImage: "bolt")
                    Spacer()
                    Text("\(reflection.energy)%")
                }
                .accessibilityElement(children: .ignore)
            }
            Section() {
                HStack {
                    Image(systemName: "calendar")
                    Text(Date(timeIntervalSince1970: TimeInterval(reflection.date)), style: .date)
                }
                HStack {
                    Image(systemName: "eyeglasses")
                    Text(reflection.axis)
                }
            }
            if !reflection.tags.isEmpty {
                Section(header: Text("Tags")) {
                    ForEach(reflection.tags, id: \.self) { tagName in
                        Text(tagName)
                    }
                }
            }
            if !reflection.note.isEmpty {
                Section(header: Text("Notes")) {
                    Text(reflection.note)
                        .lineLimit(3)
                        .frame(minHeight: 100, alignment: .topLeading)
                }
            }
            
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: Button("Edit") {
            editAction()
        })
        .navigationTitle(reflection.name.isEmpty ? "Activity Name" : reflection.name)
        .fullScreenCover(isPresented: $isPresented) {
            NavigationView {
                EditView(
                    dataStore: dataStore,
                    data: $data
                )
                    .navigationBarItems(leading: Button("Cancel") {
                        isPresented = false
                    }, trailing: Button("Done") {
                        isPresented = false
                        reflection.update(from: data)
                        saveAction(reflection)
                    })
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static func saveAction(reflection: Reflection) -> Void { }
    static var previews: some View {
        NavigationView {
            DetailView(
                dataStore: DataStore.createExample(),
                reflection: .constant(Reflection.exampleData[0]),
                saveAction: saveAction
            )
        }
    }
}
