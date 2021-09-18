// Wayfinder

import SwiftUI

struct ErrorMessage: Identifiable {
    var id: String { title + message }
    let title: String
    let message: String
}

struct ListView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var isNewReflectionPresented = false
    @State private var isCreatingExport = false
    @State private var errorMessage: ErrorMessage?
    
    var reflectionsByDate: [Date: [Reflection]] {
        // TODO consider setting standard time of day when creating/editing instead of converting on the fly
        // Converts all datetimes to be at the same time of day to simulate grouping by day
        Dictionary(grouping: dataStore.reflections, by: { Calendar.current.startOfDay(for: $0.data.date) })
    }
    
    var dates: [Date] {
        reflectionsByDate.map({ $0.key }).sorted(by: >)
    }
    
    func updateAction(reflection: Reflection) -> Void {
        dataStore.update(reflection: reflection)
    }
    
    func deleteAction(ids: [Int64]) -> Void {
        dataStore.delete(reflectionIds: ids)
    }
    
    func shareSheet() {
        isCreatingExport = true
        defer {
            isCreatingExport = false
        }
        dataStore.ExportCsv() { result in
            switch result {
            case .failure(let error):
                errorMessage = ErrorMessage(title: "Export Error", message: error.localizedDescription)
                
            case .success(let csv):
                let activityVC = UIActivityViewController(
                    activityItems: [csv],
                    applicationActivities: nil
                )
                UIApplication.shared.windows.first?.rootViewController?.present(
                    activityVC, animated: true, completion: nil
                )
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dates, id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        let reflectionsThisDate = reflectionsByDate[date]!
                        ForEach(reflectionsThisDate) { r in
                            let index = dataStore.reflections.firstIndex(where: {$0.id == r.id})!
                            NavigationLink(
                                destination: DetailView(
                                    reflection: $dataStore.reflections[index],
                                    existingNames: dataStore.uniqueReflectionNames,
                                    saveAction: updateAction
                                )
                            ) {
                                CardView(reflection: dataStore.reflections[index])
                            }
                        }
                        .onDelete{
                            deleteAction(ids: $0.map { reflectionsThisDate[$0].id })
                        }
                    }
                }
            }
            .navigationTitle("Reflections")
            .navigationBarItems(
                leading:
                    Button(action: shareSheet) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(isCreatingExport),
                trailing:
                    Button(action: {
                        isNewReflectionPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
            )
            .listStyle(GroupedListStyle())
        }
        .sheet(isPresented: $isNewReflectionPresented) {
            EditViewSheet(
                dataStore: dataStore,
                isPresented: $isNewReflectionPresented
            )
        }
        .alert(item: $errorMessage) { msg in
            Alert(title: Text(msg.title), message: Text(msg.message), dismissButton: .cancel())
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(dataStore: DataStore.createExample())
    }
}
