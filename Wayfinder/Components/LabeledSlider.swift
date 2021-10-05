// Wayfinder

import SwiftUI

struct LabeledSlider: View {
    let label: String
    @Binding var value: Int64
    var range: ClosedRange<Double>
    
    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
            }
            HStack {
                Slider(
                    value: Binding<Double>(
                        get: { return Double(value) },
                        set: { value = Int64(truncating: $0 as NSNumber) }),
                    in: range,
                    step: 1
                )
                Text("\(value, specifier: "%+d%%")")
                    .frame(minWidth: 50)
            }
        }
    }
}

struct LabeledSlider_Previews: PreviewProvider {
    static var previews: some View {
        LabeledSlider(label: "My Property", value: .constant(20), range: 0...100)
    }
}
