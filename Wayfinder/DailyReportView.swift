// Wayfinder

import SwiftUI

struct DailyReportView: View {
    @ObservedObject var dbData: DbData
    
    @State var selectedDay: Date = Date()
    @State var averagedResult: Reflection.Averaged? = nil
    
    private func updateResult(date: Date) {
        dbData.report(for: date) { results in
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
                Text("Daily Averages")
                    .font(.title)
                Spacer()
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
                    updateResult(date: newDate)
                })
                Spacer()
            }
            List {
            if averagedResult != nil {
                let result = averagedResult!
                HStack {
                    Label("Observations", systemImage: "calendar")
                    Spacer()
                    Text("\(result.ids.count)")
                }
                HStack {
                    Label("Flow States", systemImage: "wind")
                    Spacer()
                    Text("\(result.flowStateYes) of \(result.flowStateYes + result.flowStateNo)")
                }
                HStack {
                    Label("Average Engagement", systemImage: "sparkles")
                    Spacer()
                    Text("\(result.engagement)")
                }
                HStack {
                    Label("Average Energy", systemImage: "bolt")
                    Spacer()
                    Text("\(result.energy)")
                }
            } else {
                Text("No reflections recorded on this day")
            }
            }
            Spacer()
        }
        .padding()
        .onAppear(perform: {
            updateResult(date: selectedDay)
        })
    }
}

struct DailyReportView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReportView(dbData: DbData.createExample())
    }
}
