// Wayfinder

import SwiftUI

enum Metric: String, CaseIterable, Identifiable {
    case engagement
    case energy
    case combined
    
    var id: String { self.rawValue }
    
    private var areInIncreasingOrder: (Reflection, Reflection) -> Bool {
        switch self {
        case .engagement:
            return {$0.engagement > $1.engagement}
        case .energy:
            return {$0.energy > $1.energy}
        case .combined:
            return {$0.engagement + $0.energy > $1.engagement + $1.energy}
        }
    }
    
    func makeComparator(direction bestWorst: BestWorst) -> ((Reflection, Reflection) -> Bool) {
        switch bestWorst {
        case .best:
            return areInIncreasingOrder
        case .worst:
            return {!areInIncreasingOrder($0, $1)}
        }
    }
}

enum BestWorst: String, CaseIterable, Identifiable {
    case best
    case worst
    
    var id: String { self.rawValue }
}

var MonthShortNames: [Int: String] = [
    1: "Jan",
    2: "Feb",
    3: "Mar",
    4: "Apr",
    5: "May",
    6: "Jun",
    7: "Jul",
    8: "Aug",
    9: "Sep",
    10: "Oct",
    11: "Nov",
    12: "Dec"
]

struct BestOfReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedBestWorst: BestWorst = .best
    @State private var selectedCategory: Category = .activity
    @State private var selectedCategoryValue: String = ""
    @State private var selectedMetric: Metric = .engagement
    @State private var result: [Reflection] = []
    @State private var isPresented: Bool = false
    
    private func updateBestOf() {
        func processResult(results: Result<[Reflection], Error>) {
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                
            case .success(let result):
                self.result = result
            }
        }
        
        let inclusionComparator = selectedCategory.makeInclusionComparator(selectedCategoryValue)
        dataStore.makeBestOfReport(inclusionComparator, by: selectedMetric, direction: selectedBestWorst, completion: processResult)
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("\(selectedBestWorst.rawValue.capitalized)", selection: $selectedBestWorst) {
                    ForEach(BestWorst.allCases) { bestWorst in
                        Text(bestWorst.rawValue.capitalized).tag(bestWorst)
                    }
                }
                .onChange(of: selectedBestWorst, perform: {_ in updateBestOf()})
                .pickerStyle(MenuPickerStyle())
                Text("of")
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
            HStack {
                Button(action: {
                    isPresented = true
                }) {
                    NameFieldView(name: selectedCategoryValue, prompt: selectedCategory.choicePrompt, font: .title2)
                        .onChange(of: selectedCategoryValue, perform: {_ in updateBestOf()})
                        .padding()
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
            List {
                if !result.isEmpty {
                    // TODO make this a nav link
                    ForEach(result.indices, id: \.self) { index in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                            CardView(reflection: result[index])
                            let date = result[index].data.date
                            let components = Calendar.current.dateComponents([.month, .day, .year], from: date)
                            VStack {
                                Text("\(MonthShortNames[components.month!] ?? "") \(components.day!)")
                                Text(String(components.year!))
                            }
                            .font(.caption)
                        }
                    }
                } else {
                    Text("No reflections found")
                }
            }
            Spacer()
        }
        .padding()
        .onAppear(perform: updateBestOf)
        .sheet(isPresented: $isPresented, onDismiss: updateBestOf) {
            switch selectedCategory {
            case .activity:
                NameView($selectedCategoryValue, nameOptions: dataStore.uniqueReflectionNames, prompt: "Choose Activity", canCreate: false)
            case .tag:
                NameView($selectedCategoryValue, nameOptions: dataStore.uniqueTagNames, prompt: "Choose Tag", canCreate: false)
            }
        }
    }
}


struct BestOfReportView_Previews: PreviewProvider {
    static var previews: some View {
        BestOfReportView(dataStore: DataStore.createExample())
    }
}
