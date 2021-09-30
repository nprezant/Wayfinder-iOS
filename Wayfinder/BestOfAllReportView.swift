// Wayfinder

import SwiftUI

struct BestOfAllReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedBestWorst: BestWorst = .best
    @State private var selectedCategory: Category = .activity
    @State private var selectedMetric: Metric = .engagement
    @State private var result: [Reflection.Averaged] = []
    @State private var errorMessage: ErrorMessage?
    
    private func updateBestOf() {
        func processResult(results: Result<[Reflection.Averaged], Error>) {
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                
            case .success(let result):
                self.result = result
            }
        }
        
        dataStore.makeBestOfAllReport(for: selectedCategory, by: selectedMetric, direction: selectedBestWorst, completion: processResult)
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
                    Text("of all")
                    Picker("\(selectedCategory.pluralized.capitalized)", selection: $selectedCategory) {
                        ForEach(Category.allCases) { category in
                            Text(category.pluralized.capitalized).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory, perform: {_ in updateBestOf()})
                    .pickerStyle(MenuPickerStyle())
                    Spacer()
                }
                .font(.title)
                .padding([.top])
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
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                            CardViewAveraged(averaged: r)
                        }
                    }
                } else {
                    Text("No \(selectedCategory.pluralized) found")
                }
            }
            .edgesIgnoringSafeArea([.leading, .trailing])
            Spacer()
        }
        .onAppear(perform: updateBestOf)
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
    }
}


struct BestOfAllReportView_Previews: PreviewProvider {
    static var previews: some View {
        BestOfAllReportView(dataStore: DataStore.createExample())
    }
}

