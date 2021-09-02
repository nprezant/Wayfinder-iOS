// Wayfinder

import SwiftUI

struct CardView: View {
    let reflection: Reflection
    var body: some View {
        VStack(alignment: .leading) {
            Text(reflection.name)
                .font(.headline)
            HStack {
                Text("\(reflection.engagement)% engagement, \(reflection.energy)% energy")
                if reflection.isFlowState.boolValue { Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor) }
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
    }
}
