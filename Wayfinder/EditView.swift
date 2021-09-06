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

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func endEditing() {
        UIApplication.shared.endEditing()
    }
}


struct EditView: View {
    @Binding var data: Reflection.Data
    let existingNames: [String]
    
    var body: some View {
        List {
            // TODO fix issue with tappable area too small
            Section() {
                NavigationLink(
                    destination: NameView(name: $data.name, nameOptions: existingNames)
                ) {
                    NameFieldView(name: data.name)
                        .contentShape(Rectangle())
                }
            }
            
            Section() {
                Toggle("Flow state", isOn: $data.isFlowState)
                    .padding(.trailing, 5)
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                ReflectionSlider(label: "Engagement", value: $data.engagement, range: 0...100)
                ReflectionSlider(label: "Energy", value: $data.energy, range: -100...100)
            }
            .onTapGesture {
                self.endEditing()
            }
            
            Section() {
                DatePicker(
                    "Date",
                    selection: $data.date,
                    displayedComponents: [.date]
                )
                // Force a rebuild on date change; there is a bug that changes the short/medium style randomly otherwise
                // https://stackoverflow.com/questions/66090210/swiftui-datepicker-jumps-between-short-and-medium-date-formats-when-changing-the
                .id(data.date)
                
                // TODO no placeholder text available yet...
                TextEditor(text: $data.note)
                    .frame(height: 100)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(
            data: .constant(Reflection.exampleData[0].data),
            existingNames: DbData.createExample().uniqueReflectionNames
        )
    }
}
