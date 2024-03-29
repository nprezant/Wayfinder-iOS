// Wayfinder

import SwiftUI

struct ListView: View {
    @ObservedObject var store: Store
    
    @State private var isNewReflectionPresented = false
    @State private var isManageAxesPresented = false
    @State private var isAboutPresented = false
    @State private var isImportFilePresented = false
    @State private var isCreatingExport = false
    @State private var errorMessage: ErrorMessage?
    
    var reflectionsByDate: [Date: [Reflection]] {
        // TODO consider setting standard time of day when creating/editing instead of converting on the fly
        // Converts all datetimes to be at the same time of day to simulate grouping by day
        Dictionary(grouping: store.reflections, by: { Calendar.current.startOfDay(for: $0.data.date) })
    }
    
    var dates: [Date] {
        reflectionsByDate.map({ $0.key }).sorted(by: >)
    }
    
    func updateAction(reflection: Reflection) -> Void {
        store.update(reflection: reflection) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Update Error", message: "\(error)")
            }
        }
    }
    
    func deleteAction(ids: [Int64]) -> Void {
        store.delete(reflectionIds: ids) { error in
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
        store.exportCsv() { result in
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
    
    func importData() {
        
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dates, id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        let reflectionsThisDate = reflectionsByDate[date]!
                        ForEach(reflectionsThisDate) { r in
                            let index = store.reflections.firstIndex(where: {$0.id == r.id})!
                            NavigationLink(
                                destination: DetailView(
                                    store: store,
                                    reflection: store.reflections[index],
                                    saveAction: updateAction
                                )
                            ) {
                                CardView(reflection: store.reflections[index])
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
            .navigationTitle("\(store.activeAxis) Reflections")
            .navigationBarItems(
                leading:
                        Menu(content: {
                            let axisNames = store.visibleAxes.map{ $0.name }
                            AxisPicker(initialAxis: store.activeAxis, axisNames: axisNames) { pickedAxis in
                                store.sync(withAxis: pickedAxis)
                            }
                            // Binds the picker to the active axis. When the active axis changes, the view is re-constructed
                            // This is necessary because the axis picker needs an updated account of the active axis, and gets
                            // the active axis value when the picker is initialized.
                            // Binding the data store's active axis directly is not advised, as it requires putting an 'onChanged'
                            // event or similar on that published property. This has the side effect of running every time that
                            // value is changed, whether it is the picker's doing or not
                            .id(store.activeAxis)
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
                            }.disabled(isCreatingExport)
                            Button(action: {isImportFilePresented = true}) {
                                Label("Import", systemImage: "square.and.arrow.down")
                            }
                            Button(action: {
                                if let url = URL(string: "https://nprezant.github.io/Wayfinder/privacy/") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Label("Privacy", systemImage: "hand.raised.fill")
                            }
                            Button(action: {
                                isAboutPresented = true
                            }) {
                                Label("About the App", systemImage: "questionmark.circle")
                            }
                        }, label: {
                            Image(systemName: "ellipsis.circle")
                                .padding([.top, .bottom])
                        })
                        Button(action: {
                            isNewReflectionPresented = true
                        }) {
                            Image(systemName: "plus")
                                .padding([.top, .bottom])
                        }
                    }
            )
            .listStyle(GroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isNewReflectionPresented) {
            EditViewSheet(
                store: store,
                isPresented: $isNewReflectionPresented,
                errorMessage: $errorMessage
            )
        }
        .sheet(isPresented: $isManageAxesPresented) {
            ManageAxesView(
                store: store,
                isPresented: $isManageAxesPresented
            )
                .dismissable(isPresented: $isManageAxesPresented)
        }
        .sheet(isPresented: $isAboutPresented) {
            AboutView()
        }
        .sheet(isPresented: $isImportFilePresented) {
            DocumentPicker(forContentTypes: [.text, .commaSeparatedText]) { urls in
                if urls.isEmpty { return }
                let fileURL = urls[0]
                store.importCsvAsync(fileURL: fileURL) { error in
                    if let error = error {
                        errorMessage = ErrorMessage(title: "Import Error", message: "\(error)")
                    }
                }
            }
        }
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(store: Store.createExample())
            .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
            .previewDisplayName("iPhone 11")
        ListView(store: Store.createExample())
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
            .previewDisplayName("iPhone 11 Pro Max")
    }
    // View device options with: xcrun simctl list devicetypes
}
