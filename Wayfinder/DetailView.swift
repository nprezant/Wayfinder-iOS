// Wayfinder

import SwiftUI

struct DetailView: View {
    @Binding var reflection: Reflection
    let existingNames: [String]
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
                Text(reflection.note)
                    .lineLimit(3)
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
                EditView(data: $data, existingNames: existingNames)
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
                existingNames: DbData.createExample().uniqueReflectionNames,
                saveAction: saveAction
            )
        }
    }
}
