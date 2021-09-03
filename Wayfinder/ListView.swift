// Wayfinder

import SwiftUI

struct ListView: View {
    @ObservedObject var dbData: DbData
    
    @State private var isNewReflectionPresented = false
    
    func updateAction(reflection: Reflection) -> Void {
        dbData.updateReflection(reflection: reflection)
    }
    
    func deleteAction(at offsets: IndexSet) -> Void {
        let toDelete = offsets.map { dbData.reflections[$0].id }
        dbData.reflections.remove(atOffsets: offsets)
        dbData.delete(reflectionIds: toDelete)
    }
    
    func shareSheet() {
        let csv = dbData.ExportCsv()
        let activityVC = UIActivityViewController(
            activityItems: [csv],
            applicationActivities: nil
        )
        UIApplication.shared.windows.first?.rootViewController?.present(
            activityVC, animated: true, completion: nil
        )
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dbData.reflections.indices, id: \.self) { index in
                    let reflection = dbData.reflections[index]
                    NavigationLink(
                        destination: DetailView(
                            reflection: $dbData.reflections[index],
                            saveAction: updateAction
                        )
                    ) {
                        CardView(reflection: reflection)
                    }
                }
                .onDelete(perform: deleteAction)
            }
            .navigationTitle("Reflections")
            .navigationBarItems(
                trailing: HStack {
                    Button(action: shareSheet) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: {
                        isNewReflectionPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            )
        }
        .sheet(isPresented: $isNewReflectionPresented) {
            EditViewSheet(
                dbData: dbData,
                dismissAction: {
                    isNewReflectionPresented = false
                },
                addAction: {
                    isNewReflectionPresented = false
                }
            )
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(dbData: DbData())
    }
}
