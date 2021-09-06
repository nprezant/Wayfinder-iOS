// Wayfinder

import SwiftUI

struct WeeklyReportView: View {
    @State var selectedDay: Date = Date()
    var result: Reflection.Averaged = Reflection.Averaged.exampleData()
    
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
                    selection: $selectedDay,
                    displayedComponents: [.date]
                )
                .id(selectedDay)
                .labelsHidden()
                Spacer()
                Text("to")
                Spacer()
                Text(Calendar.current.date(byAdding: .day, value: 7, to: selectedDay)!, style: .date)
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

struct WeeklyReportView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyReportView()
    }
}
