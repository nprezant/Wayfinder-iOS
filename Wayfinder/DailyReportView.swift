// Wayfinder

import SwiftUI

struct DailyReportView: View {
    @ObservedObject var dataStore: DataStore
    @State var showHeader: Bool = true
    
    @State private var selectedDay: Date = Date()
    @State private var averagedResult: Reflection.Averaged? = nil
    
    private func updateAverages(date: Date) {
        dataStore.makeAverageReport(for: date) { results in
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
            VStack {
                if showHeader {
                    HStack {
                        Text("Daily Average")
                            .font(.title)
                        Spacer()
                    }
                    .padding([.top])
                }
                HStack {
                    DatePicker(
                        "Date",
                        selection: $selectedDay,
                        displayedComponents: [.date]
                    )
                    .id(selectedDay)
                    .labelsHidden()
                    .onChange(of: selectedDay, perform: { newDate in
                        updateAverages(date: newDate)
                    })
                    Spacer()
                }
            }
            .padding()
            ReportListView(averagedResult: averagedResult)
                .edgesIgnoringSafeArea([.leading, .trailing])
            Spacer()
        }
        .onAppear(perform: {
            updateAverages(date: selectedDay)
        })
    }
}

struct DailyReportView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReportView(dataStore: DataStore.createExample())
    }
}
