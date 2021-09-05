// Wayfinder

import SwiftUI

struct ListView: View {
    @ObservedObject var dbData: DbData
    
    @State private var isNewReflectionPresented = false
    
    var reflectionsByDate: [Date: [Reflection]] {
        // TODO consider setting standard time of day when creating/editing instead of converting on the fly
        // Converts all datetimes to be at the same time of day to simulate grouping by day
        Dictionary(grouping: dbData.reflections, by: { Calendar.current.startOfDay(for: $0.data.date) })
    }
    
    var dates: [Date] {
        reflectionsByDate.map({ $0.key }).sorted(by: >)
    }
    
    func updateAction(reflection: Reflection) -> Void {
        dbData.update(reflection: reflection)
    }
    
    func deleteAction(at offsets: IndexSet) -> Void {
        let toDelete = offsets.map { dbData.reflections[$0].id }
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
                ForEach(dates, id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        ForEach(reflectionsByDate[date]!) { r in
                            let index = dbData.reflections.firstIndex(where: {$0.id == r.id})!
                            NavigationLink(
                                destination: DetailView(
                                    reflection: $dbData.reflections[index],
                                    saveAction: updateAction
                                )
                            ) {
                                CardView(reflection: dbData.reflections[index])
                            }
                        }
                        .onDelete(perform: deleteAction)
                    }
                }
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
            .listStyle(GroupedListStyle())
        }
        .sheet(isPresented: $isNewReflectionPresented) {
            EditViewSheet(
                dbData: dbData,
                isPresented: $isNewReflectionPresented
            )
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(dbData: DbData.createExample())
    }
}
