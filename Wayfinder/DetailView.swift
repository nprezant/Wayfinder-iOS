// Wayfinder

import SwiftUI

struct DetailView: View {
    @Binding var reflection: Reflection
    let existingReflections: [String]
    let saveAction: ((Reflection) -> Void)
    
    @State private var data: Reflection.Data = Reflection.Data()
    @State private var isPresented = false
    
    var body: some View {
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
            }
            Section() {
                if reflection.tags.isEmpty {
                    Text("No tags")
                } else {
                    ForEach(reflection.tags, id: \.self) { tagName in
                        Text(tagName)
                    }
                }
            }
            Section() {
                if reflection.note.isEmpty {
                    Text("No additional notes")
                        .frame(minHeight: 100, alignment: .topLeading)
                } else {
                    Text(reflection.note)
                        .lineLimit(3)
                        .frame(minHeight: 100, alignment: .topLeading)
                }
            }

        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: Button("Edit") {
            isPresented = true
            data = reflection.data
        })
        .navigationTitle(reflection.name.isEmpty ? "Activity Name" : reflection.name)
        .fullScreenCover(isPresented: $isPresented) {
            NavigationView {
                EditView(data: $data, existingReflections: existingReflections)
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
                reflection: .constant(Reflection.exampleData[0]),
                existingReflections: DataStore.createExample().uniqueReflectionNames,
                saveAction: saveAction
            )
        }
    }
}
