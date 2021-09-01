// Wayfinder

import SwiftUI

struct ListView: View {
    @ObservedObject var dbData: DbData
    
    func saveAction(reflection: Reflection) -> Void {
        dbData.updateReflection(reflection: reflection)
    }
    
    func deleteAction(at offsets: IndexSet) -> Void {
        let toDelete = offsets.map { dbData.reflections[$0].id }
        dbData.reflections.remove(atOffsets: offsets)
        dbData.delete(reflectionIds: toDelete)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dbData.reflections.indices, id: \.self) { index in
                    let reflection = dbData.reflections[index]
                    NavigationLink(
                        destination: DetailView(
                            reflection: $dbData.reflections[index],
                            saveAction: saveAction
                        )
                    ) {
                        CardView(reflection: reflection)
                    }
                }
                .onDelete(perform: deleteAction)
            }
            .navigationTitle("Reflections")
            .navigationBarItems(
                trailing: Button(action: { /* TODO show sheet */ }) {
                    Image(systemName: "square.and.arrow.up")
                }
            )
        }
    }

    private func binding(for reflection: Reflection) -> Binding<Reflection> {
        guard let reflectionIndex = dbData.reflections.firstIndex(
                where: { $0.id == reflection.id }
        ) else {
            fatalError("Can't find reflection in array")
        }
        return $dbData.reflections[reflectionIndex]
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(dbData: DbData())
    }
}
