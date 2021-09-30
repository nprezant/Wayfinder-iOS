// Wayfinder

import SwiftUI

struct CardView: View {
    let reflection: Reflection
    var body: some View {
        VStack(alignment: .leading) {
            Text(reflection.name)
                .font(.body)
                .lineLimit(2)
            HStack {
                Text("Engagement: \(reflection.engagement)%, Energy: \(reflection.energy)%")
                if reflection.isFlowState.boolValue {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
                Spacer()
            }
            .font(.caption)
        }
        .foregroundColor(.primary)
        .padding(.leading).padding(.trailing)
    }
}

struct CardViewAveraged: View {
    let averaged: Reflection.Averaged
    var body: some View {
        VStack(alignment: .leading) {
            Text(averaged.label ?? "[No label specified]")
                .font(.body)
                .lineLimit(2)
            HStack {
                Text("Engagement: \(averaged.engagement)%, Energy: \(averaged.energy)%, Flow: \(averaged.flowStateYes) of \(averaged.flowStateYes + averaged.flowStateNo)")
                Spacer()
            }
            .font(.caption)
        }
        .foregroundColor(.primary)
        .padding(.leading).padding(.trailing)
    }
}

struct CardView_Previews: PreviewProvider {
    static var reflection = Reflection.exampleData[0]
    static var previews: some View {
        CardView(reflection: reflection)
            .previewDevice(PreviewDevice(rawValue: "iPhone 7"))
            .previewLayout(.fixed(width: 300, height: 60))
        CardViewAveraged(averaged: Reflection.Averaged.exampleData())
    }
}
