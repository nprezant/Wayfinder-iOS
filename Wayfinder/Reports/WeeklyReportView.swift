// Wayfinder

import SwiftUI
import os

struct WeeklyReportView: View {
    @ObservedObject var dataStore: DataStore
    @State var showHeader: Bool = true
    
    @State private var selectedStartDay: Date = Date().minusOneWeek
    @State private var selectedEndDay: Date = Date()
    @State private var averagedResult: Reflection.Averaged? = nil
    
    private func updateAverages(start: Date, end: Date) {
        dataStore.makeAverageReport(for: start, to: end) { results in
            switch results {
            case .failure(let error):
                Logger().error("\(error.localizedDescription)")
                
            case .success(let averagedResult):
                self.averagedResult = averagedResult
            }
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                if showHeader {
                    HStack {
                        Text("Weekly Average")
                            .font(.title)
                        Spacer()
                    }
                    .padding([.top])
                }
                HStack {
                    DatePicker(
                        "Date",
                        selection: $selectedStartDay,
                        displayedComponents: [.date]
                    )
                    .id(selectedStartDay)
                    .labelsHidden()
                    .onChange(of: selectedStartDay, perform: { newStartDay in
                        selectedEndDay = newStartDay.plusOneWeek
                        updateAverages(start: newStartDay, end: selectedEndDay)
                    })
                    Spacer()
                    Text("to")
                    Spacer()
                    DatePicker(
                        "Date",
                        selection: $selectedEndDay,
                        displayedComponents: [.date]
                    )
                    .id(selectedEndDay)
                    .labelsHidden()
                    .onChange(of: selectedEndDay, perform: { newEndDay in
                        updateAverages(start: selectedStartDay, end: newEndDay)
                    })
                }
            }
            .padding()
            AveragedResultView(averagedResult: averagedResult)
                .edgesIgnoringSafeArea([.leading, .trailing])
            Spacer()
        }
        .onAppear(perform: {
            selectedEndDay = selectedStartDay.plusOneWeek
            updateAverages(start: selectedStartDay, end: selectedEndDay)
        })
    }
}

struct WeeklyReportView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyReportView(dataStore: DataStore.createExample())
    }
}
