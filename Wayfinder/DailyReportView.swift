// Wayfinder

import SwiftUI

struct DailyReportView: View {
    @State var selectedDay: Date = Date()
    var result: Reflection.Averaged = Reflection.Averaged.exampleData()
    
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
                Spacer()
            }
            HStack {
                Label("Flow State?", systemImage: "wind")
                Spacer()
                Text("\(result.flowStateYes) of \(result.flowStateYes + result.flowStateNo)")
            }
            HStack {
                Label("Engagement", systemImage: "sparkles")
                Spacer()
                Text("\(result.engagement)")
            }
            HStack {
                Label("Energy", systemImage: "bolt")
                Spacer()
                Text("\(result.energy)")
            }
            Spacer()
        }
        .padding()
    }
}

struct DailyReportView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReportView()
    }
}
