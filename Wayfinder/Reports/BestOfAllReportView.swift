// Wayfinder

import SwiftUI
import os

struct BestOfAllReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedBestWorst: BestWorst = .best
    @State private var selectedCategory: Category = .activity
    @State private var selectedMetric: Metric = .engagement
    @State private var result: [Reflection.Averaged] = []
    @State private var errorMessage: ErrorMessage?
    @State private var isBestOfPresented: Bool = false
    @State private var bestOfUpdatedData: Bool = false
    @State private var selectedAverage: Reflection.Averaged?
    
    private func updateBestOfAll() {
        dataStore.makeBestOfAllReport(for: selectedCategory, by: selectedMetric, direction: selectedBestWorst) { results in
            switch results {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
            case .success(let result):
                self.result = result
            }
        }
    }
    
    private func updateBestOfAllIfBestOfMadeChanges() {
        if bestOfUpdatedData {
            updateBestOfAll()
            bestOfUpdatedData = false
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
                    .onChange(of: selectedBestWorst, perform: {_ in updateBestOfAll()})
                    .pickerStyle(MenuPickerStyle())
                    Text("of all \(dataStore.activeAxis)")
                    Picker("\(selectedCategory.pluralized.capitalized)", selection: $selectedCategory) {
                        ForEach(Category.allCases) { category in
                            Text(category.pluralized.capitalized).tag(category)
                        }
                    }
                    .onChange(of: selectedCategory, perform: {_ in updateBestOfAll()})
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
                .onChange(of: selectedMetric, perform: {_ in updateBestOfAll()})
                .pickerStyle(SegmentedPickerStyle())
                // Still silly.
                // https://developer.apple.com/forums/thread/652080
                let _ = "\(selectedAverage?.label ?? "none")"
                // TODO add date range toggle. Off = any. On = can choose. Or another picker?
            }
            .padding()
            List {
                if !result.isEmpty {
                    ForEach(Array(zip(result.indices, result)), id: \.0) { index, r in
                        Button {
                            selectedAverage = r
                            isBestOfPresented = true
                        } label: {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption)
                                CardViewAveraged(averaged: r)
                            }
                        }
                    }
                } else {
                    Text("No \(selectedCategory.pluralized) found")
                }
            }
            .edgesIgnoringSafeArea([.leading, .trailing])
            Spacer()
        }
        .onAppear(perform: updateBestOfAll)
        .alert(item: $errorMessage) { msg in
            msg.toAlert()
        }
        .sheet(isPresented: $isBestOfPresented, onDismiss: updateBestOfAllIfBestOfMadeChanges) {
            if selectedAverage != nil {
                BestOfReportView(dataStore: dataStore, selectedBestWorst: selectedBestWorst, selectedCategory: selectedCategory, selectedCategoryValue: selectedAverage!.label ?? "[No group label]", wasUpdated: $bestOfUpdatedData)
            }
        }
    }
}


struct BestOfAllReportView_Previews: PreviewProvider {
    static var previews: some View {
        BestOfAllReportView(dataStore: DataStore.createExample())
    }
}

