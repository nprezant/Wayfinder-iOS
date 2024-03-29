// Wayfinder

import SwiftUI
import os

struct DailyReportView: View {
    @ObservedObject var store: Store
    @State var showHeader: Bool = true
    
    @State private var selectedDay: Date = Date()
    @State private var averagedResult: Reflection.Averaged? = nil
    
    private func updateAverages(date: Date) {
        store.makeAverageReport(for: date) { results in
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
            AveragedResultView(averagedResult: averagedResult)
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
        DailyReportView(store: Store.createExample())
    }
}
