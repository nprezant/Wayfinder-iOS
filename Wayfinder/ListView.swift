// Wayfinder

import SwiftUI

struct ListView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var isNewReflectionPresented = false
    @State private var isManageAxesPresented = false
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
        dataStore.update(reflection: reflection) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Update Error", message: "\(error)")
            }
        }
    }
    
    func deleteAction(ids: [Int64]) -> Void {
        dataStore.delete(reflectionIds: ids) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Delete Error", message: "\(error)")
            }
        }
    }
    
    func shareSheet() {
        isCreatingExport = true
        defer {
            isCreatingExport = false
        }
        dataStore.ExportCsv() { result in
            switch result {
            case .failure(let error):
                errorMessage = ErrorMessage(title: "Export Error", message: "\(error)")
                
            case .success(let csv):
                let activityVC = UIActivityViewController(
                    activityItems: [csv],
                    applicationActivities: nil
                )
                if let ppc = activityVC.popoverPresentationController {
                    let popupWidth = 300
                    let popupHeight = 350
                    let x = 0.5 * (UIScreen.main.bounds.width - CGFloat(popupWidth))
                    let y = 0.5 * (UIScreen.main.bounds.height - CGFloat(popupHeight))
                    ppc.sourceView = UIApplication.shared.windows.first
                    ppc.sourceRect = CGRect(x: Int(x), y: Int(y), width: popupWidth, height: popupHeight)
                    ppc.permittedArrowDirections = []
                }
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
                                    dataStore: dataStore,
                                    reflection: dataStore.reflections[index],
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
                if dates.isEmpty {
                    Button {
                        isNewReflectionPresented = true
                    } label: {
                        HStack { Text("Tap"); Image(systemName: "plus"); Text("to create a reflection") }
                    }
                }
            }
            .navigationTitle("\(dataStore.activeAxis) Reflections")
            .navigationBarItems(
                leading:
                        Menu(content: {
                            let axisNames = dataStore.visibleAxes.map{ $0.name }
                            Picker(selection: $dataStore.activeAxis, label: Image(systemName: "eyeglasses")) {
                                ForEach(axisNames, id: \.self) { axis in
                                    Text(axis)
                                }
                            }
                            Button(action: {
                                isManageAxesPresented = true
                            }) {
                                Label("Manage views", systemImage: "gear")
                            }
                        }, label: {
                            Image(systemName: "eyeglasses")
                                .font(Font.title2.weight(.bold))
                        }),
                trailing:
                    HStack {
                        Menu(content: {
                            Button(action: shareSheet) {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .disabled(isCreatingExport)
                            Button(action: {
                                if let url = URL(string: "https://nprezant.github.io/Wayfinder/privacy/") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("Privacy", systemImage: "hand.raised.fill")
                            }
                        }, label: {
                            Image(systemName: "ellipsis.circle")
                        })
                        .padding([.leading])
                        Button(action: {
                            isNewReflectionPresented = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .padding([.leading])
                    }
            )
            .listStyle(GroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isNewReflectionPresented) {
            EditViewSheet(
                dataStore: dataStore,
                isPresented: $isNewReflectionPresented,
                errorMessage: $errorMessage
            )
        }
        .sheet(isPresented: $isManageAxesPresented) {
            ManageAxesView(
                dataStore: dataStore
            )
        }
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(dataStore: DataStore.createExample())
            .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
            .previewDisplayName("iPhone 11")
        ListView(dataStore: DataStore.createExample())
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
            .previewDisplayName("iPhone 11 Pro Max")
    }
    // View device options with: xcrun simctl list devicetypes
}
