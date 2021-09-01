// Wayfinder

import SwiftUI

struct CardView: View {
    let reflection: Reflection
    var body: some View {
        VStack(alignment: .leading) {
            Text(reflection.name)
                .font(.headline)
            Spacer()
            HStack {
                Spacer()
                Label("\(reflection.engagement)", systemImage: "sparkles")
                    .frame(width: 75)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Engagement"))
                    .accessibilityValue(Text("\(reflection.engagement)"))
                Label("\(reflection.energy)", systemImage: "bolt")
                    .frame(width: 75)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Energy"))
                    .accessibilityValue(Text("\(reflection.energy)"))
                let checkName = reflection.isFlowState.boolValue ? "checkmark.circle.fill" : "checkmark.circle"
                Label(
                    "\(Image(systemName: checkName))", systemImage: "wind")
                    .frame(width: 75)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Is Flow State"))
            }
            .font(.caption)
        }
        .padding()
        .foregroundColor(.black)
    }
}

struct CardView_Previews: PreviewProvider {
    static var reflection = Reflection.exampleData[0]
    static var previews: some View {
        CardView(reflection: reflection)
//            .background(Color.yellow)
            .previewLayout(.fixed(width: 300, height: 60))
    }
}
