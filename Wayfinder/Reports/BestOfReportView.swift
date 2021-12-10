// Wayfinder

import SwiftUI
import os

struct BestOfReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State public var selectedBestWorst: BestWorst = .best
    @State public var selectedCategory: Category = .activity
    @State public var selectedCategoryValue: String = ""
    @State public var selectedMetric: Metric = .combined
    public var wasUpdated: Binding<Bool>?

    @State private var result: [Reflection] = []
    @State private var errorMessage: ErrorMessage?
    @State private var isPresented: Bool = false
    @State private var isDetailPresented: Bool = false
    @State private var reflectionToEdit: Reflection?
    
    private func updateBestOf() {
        func processResult(results: Result<[Reflection], Error>) {
            switch results {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
                
            case .success(let result):
                self.result = result
            }
        }
        
        let inclusionComparator = selectedCategory.makeInclusionComparator(selectedCategoryValue)
        dataStore.makeBestOfReport(inclusionComparator, by: selectedMetric, direction: selectedBestWorst, completion: processResult)
    }
    
    func updateAction(reflection: Reflection) -> Void {
        dataStore.update(reflection: reflection) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Update Error", message: "\(error)")
            }
            updateBestOf()
            wasUpdated?.wrappedValue = true
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Menu(content: {
                        Picker(selection: $selectedBestWorst, label: Text(selectedBestWorst.rawValue.capitalized)) {
                            ForEach(BestWorst.allCases) { bestWorst in
                                Text(bestWorst.rawValue.capitalized).tag(bestWorst)
                            }
                        }
                    }, label: {
                        Text(selectedBestWorst.rawValue.capitalized)
                    })
                    .onChange(of: selectedBestWorst, perform: {_ in updateBestOf()})
                    Text("of a \(dataStore.activeAxis)")
                    Menu(content: {
                        Picker(selection: $selectedCategory, label: Text(selectedCategory.rawValue.capitalized)) {
                            ForEach(Category.allCases) { category in
                                Text(category.rawValue.capitalized).tag(category)
                            }
                        }
                    }, label: {
                        Text(selectedCategory.rawValue.capitalized)
                    })
                    .onChange(of: selectedCategory, perform: {_ in updateBestOf()})
                    Spacer()
                }
                .font(.title)
                .padding([.top, .bottom])
                HStack {
                    Button(action: {
                        isPresented = true
                    }) {
                        NamePickerField(name: selectedCategoryValue, prompt: selectedCategory.choicePrompt, font: .title2)
                            .onChange(of: selectedCategoryValue, perform: {_ in updateBestOf()})
                            .padding([.leading, .trailing])
                            .background(RoundedRectangle(cornerRadius: 8).foregroundColor(Color.secondary.opacity(0.15)))
                    }
                    Spacer()
                }
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(Metric.allCases) { metric in
                        Text(metric.rawValue.capitalized).tag(metric)
                    }
                }
                .onChange(of: selectedMetric, perform: {_ in updateBestOf()})
                .pickerStyle(SegmentedPickerStyle())
                // TODO add date range toggle. Off = any. On = can choose. Or another picker?
            }
            .padding()
            List {
                if !result.isEmpty {
                    // https://stackoverflow.com/questions/59295206/how-do-you-use-enumerated-with-foreach-in-swiftui
                    ForEach(Array(zip(result.indices, result)), id: \.0) { index, r in
                        Button(action: {
                            reflectionToEdit = r
                            isDetailPresented = true
                        }) {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                CardView(reflection: r)
                                let date = r.data.date
                                let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
                                VStack {
                                    Text("\(MonthShortNames[components.month!] ?? "") \(components.day!)")
                                    Text(String(components.year!))
                                }
                                .font(.caption)
                            }
                        }
                    }
                } else {
                    Text("No reflections found")
                }
            }
            .edgesIgnoringSafeArea([.leading, .trailing])
            // Very silly.
            // Seems to be bug with nullable state variables.
            // Value won't stay set without this
            // https://developer.apple.com/forums/thread/652080
            let _ = "\(reflectionToEdit ?? Reflection.exampleData[0])"
            Spacer()
        }
        .onAppear(perform: updateBestOf)
        .sheet(isPresented: $isPresented, onDismiss: updateBestOf) {
            switch selectedCategory {
            case .activity:
                NamePicker($selectedCategoryValue, nameOptions: dataStore.activityNames, prompt: "Choose Activity", canCreate: false, parentIsPresenting: $isPresented)
            case .tag:
                NamePicker($selectedCategoryValue, nameOptions: dataStore.tagNames, prompt: "Choose Tag", canCreate: false, parentIsPresenting: $isPresented)
            }
        }
        .sheet(isPresented: $isDetailPresented) {
            if let r = reflectionToEdit {
                DetailView(
                    dataStore: dataStore,
                    reflection: r,
                    saveAction: updateAction,
                    parentIsPresenting: $isDetailPresented
                )
            }
            else {
                EmptyView()
            }
        }
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
    }
}

struct BestOfReportView_Previews: PreviewProvider {
    static var previews: some View {
        BestOfReportView(dataStore: DataStore.createExample())
    }
}
