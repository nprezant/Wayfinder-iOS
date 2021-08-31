// Wayfinder

import SwiftUI

struct ReflectionSlider: View {
    let label: String
    @Binding var value: Int64
    var range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
            Spacer()
        }.contentShape(Rectangle()) // Makes entire HStack tappable
        Slider(
            value: Binding<Double>(
                get: { return Double(value) },
                set: { value = Int64(truncating: $0 as NSNumber) }),
            in: range,
            step: 1
        )
    }
}

struct EditView: View {
    @Binding var reflectionData: Reflection.Data
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack {
                TextField("Activity name", text: $reflectionData.name)
                    .font(.system(size: 26))
                Spacer()
            }
            Toggle("Flow state", isOn: $reflectionData.isFlowState)
                .padding(.trailing, 5)
                .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
            ReflectionSlider(label: "Engagement", value: $reflectionData.engagement, range: 0...100)
            ReflectionSlider(label: "Energy", value: $reflectionData.energy, range: -100...100)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(reflectionData: .constant(Reflection.exampleData[0].data))
    }
}
