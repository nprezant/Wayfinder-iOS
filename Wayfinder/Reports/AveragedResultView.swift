// Wayfinder

import SwiftUI

struct AveragedResultView: View {
    let averagedResult: Reflection.Averaged?
    
    var body: some View {
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
                    Text("\(result.engagement)%")
                }
                HStack {
                    Label("Average Energy", systemImage: "bolt")
                    Spacer()
                    Text("\(result.energy)%")
                }
            } else {
                Text("No reflections found")
            }
        }
    }
}

struct AveragedResultView_Previews: PreviewProvider {
    static var previews: some View {
        AveragedResultView(averagedResult: Reflection.Averaged.exampleData())
    }
}
