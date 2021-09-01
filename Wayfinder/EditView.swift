// Wayfinder

import SwiftUI

struct ReflectionSlider: View {
    let label: String
    @Binding var value: Int64
    var range: ClosedRange<Double>

    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
            }
            Slider(
                value: Binding<Double>(
                    get: { return Double(value) },
                    set: { value = Int64(truncating: $0 as NSNumber) }),
                in: range,
                step: 1
            )
        }
    }
}

struct EditView: View {
    @Binding var data: Reflection.Data
    var body: some View {
        List {
            VStack {
                HStack {
                    TextField("Activity name", text: $data.name)
                        .font(.largeTitle)
                    Spacer()
                }
                Toggle("Flow state", isOn: $data.isFlowState)
                    .padding(.trailing, 5)
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                ReflectionSlider(label: "Engagement", value: $data.engagement, range: 0...100)
                ReflectionSlider(label: "Energy", value: $data.energy, range: -100...100)
            }
            
            Section(header: Text("System Info")) {
                DatePicker(
                    "Date",
                    selection: $data.date,
                    displayedComponents: [.date]
                )
                // Can use .labelsHidden() to provide own label
                .datePickerStyle(DefaultDatePickerStyle())
                
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(data: .constant(Reflection.exampleData[0].data))
    }
}
