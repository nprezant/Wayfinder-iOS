// Wayfinder

import SwiftUI

struct DetailView: View {
    @Binding var reflection: Reflection
    @State private var data: Reflection.Data = Reflection.Data()
    @State private var isPresented = false
    var body: some View {
        List {
            Section(header: Text("Main Info")) {
                HStack {
                    Label("Flow State?", systemImage: "wind")
                        .accessibilityLabel(Text("Is Flow State?"))
                    Spacer()
                    Image(systemName: reflection.isFlowState.boolValue ? "checkmark.circle.fill" : "checkmark.circle").foregroundColor(.blue)
                }
                HStack {
                    Label("Engagement", systemImage: "sparkles")
                        .accessibilityLabel(Text("Engagement"))
                    Spacer()
                    Text("\(reflection.engagement)")
                }
                HStack {
                    Label("Energy", systemImage: "bolt")
                        .accessibilityLabel(Text("Energy"))
                    Spacer()
                    Text("\(reflection.energy)")
                }
                .accessibilityElement(children: .ignore)
            }
            Section(header: Text("System Info")) {
                HStack {
                    Image(systemName: "calendar")
                    Text(Date(timeIntervalSince1970: TimeInterval(reflection.date)), style: .date)
                }
            }

        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: Button("Edit") {
            isPresented = true
            data = reflection.data
        })
        .navigationTitle(reflection.name)
        .fullScreenCover(isPresented: $isPresented) {
            NavigationView {
                EditView(data: $data)
                    .navigationBarItems(leading: Button("Cancel") {
                        isPresented = false
                    }, trailing: Button("Done") {
                        isPresented = false
                        reflection.update(from: data)
                    })
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailView(reflection: .constant(Reflection.exampleData[0]))
        }
    }
}
