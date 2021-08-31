// Wayfinder

import SwiftUI

struct ListView: View {
    @Binding var reflections: [Reflection]
    var body: some View {
        Text("Hello")
//        List {
//            ForEach(reflections) { reflection in
//                NavigationLink(destination: DetailView(scrum: binding(for: reflection))) {
//                    CardView(reflection: reflection)
//                }
//                .listRowBackground(Color.gray)
//            }
//        }

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
