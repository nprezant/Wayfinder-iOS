// Wayfinder

import SwiftUI

struct WeeklyReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State var selectedStartDay: Date = Date()
    @State var selectedEndDay: Date = Date()
    @State var averagedResult: Reflection.Averaged? = nil
    
    private func updateAverages(start: Date, end: Date) {
        dataStore.makeAverageReport(for: start, to: end) { results in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                
            case .success(let averagedResult):
                self.averagedResult = averagedResult
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Weekly Averages")
                    .font(.title)
                Spacer()
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
            ReportListView(averagedResult: averagedResult)
            Spacer()
        }
        .padding()
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
