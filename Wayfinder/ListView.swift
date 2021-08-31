// Wayfinder

import SwiftUI

struct ListView: View {
    @Binding var reflections: [Reflection]
    var body: some View {
        NavigationView {
            List {
                ForEach(reflections.indices) { index in
                    let reflection = reflections[index]
                    NavigationLink(destination: DetailView(reflection: binding(for: reflection))) {
                        CardView(reflection: reflection)
                    }
                    .listRowBackground(Color.green)
                }
            }
            .navigationTitle("Reflections")
            .navigationBarItems(trailing: Button(action: {
                // TODO show sheet
            }) {
                Image(systemName: "square.and.arrow.up")
            })
        }
    }

    private func binding(for reflection: Reflection) -> Binding<Reflection> {
        guard let reflectionIndex = reflections.firstIndex(where: { $0.id == reflection.id }) else {
            fatalError("Can't find reflection in array")
        }
        return $reflections[reflectionIndex]
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(reflections: .constant(Reflection.exampleData))
    }
}
