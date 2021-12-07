// Wayfinder

import SwiftUI
import os

struct BestOfReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State public var selectedBestWorst: BestWorst = .best
    @State public var selectedCategory: Category = .activity
    @State public var selectedCategoryValue: String = ""
    @State public var selectedMetric: Metric = .engagement

    @State private var result: [Reflection] = []
    @State private var errorMessage: ErrorMessage?
    @State private var isPresented: Bool = false
    @State private var isDetailPresented: Bool = false
    @State private var dsIndexToEdit: Int?
    
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
    
    func updateEditedReflection() -> Void {
        guard let index = dsIndexToEdit else { return }
        let reflection = dataStore.reflections[index]
        dataStore.update(reflection: reflection) { error in
            if let error = error {
                errorMessage = ErrorMessage(title: "Update Error", message: "\(error)")
            }
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Picker("\(selectedBestWorst.rawValue.capitalized)", selection: $selectedBestWorst) {
                        ForEach(BestWorst.allCases) { bestWorst in
                            Text(bestWorst.rawValue.capitalized).tag(bestWorst)
                        }
                    }
                    .onChange(of: selectedBestWorst, perform: {_ in updateBestOf()})
                    .pickerStyle(MenuPickerStyle())
                    Text("of a \(dataStore.activeAxis)")
                    Picker("\(selectedCategory.rawValue.capitalized)", selection: $selectedCategory) {
                        ForEach(Category.allCases) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory, perform: {_ in updateBestOf()})
                    .pickerStyle(MenuPickerStyle())
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
                    ForEach(result.indices, id: \.self) { index in
                        let r = result[index]
                        let dataStoreIndex = dataStore.reflections.firstIndex(where: {$0.id == r.id})!
                        Button(action: {
                            dsIndexToEdit = dataStoreIndex
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
            let _ = "\(dsIndexToEdit ?? 1)"
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
        .sheet(isPresented: $isDetailPresented, onDismiss: updateEditedReflection) {
            if let dsIndex = dsIndexToEdit {
                DetailView(
                    dataStore: dataStore,
                    reflection: dataStore.reflections[dsIndex],
                    saveAction: {_ in updateEditedReflection()},
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
