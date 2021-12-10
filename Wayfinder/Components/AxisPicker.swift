// Wayfinder

import SwiftUI

struct AxisPicker: View {
    @State private var activeAxis: String
    private var axisNames: [String]
    private var onAxisPicked: (String)->Void
    
    init(initialAxis: String, axisNames: [String], onAxisPicked: @escaping (String)->Void) {
        self._activeAxis = State(initialValue: initialAxis)
        self.axisNames = axisNames
        self.onAxisPicked = onAxisPicked
    }
    
    var body: some View {
        Picker(selection: $activeAxis, label: Image(systemName: "eyeglasses")) {
            ForEach(axisNames, id: \.self) { axis in
                Text(axis)
            }
        }
        .onChange(of: activeAxis) { newActiveAxis in
            onAxisPicked(newActiveAxis)
        }
    }
}

struct AxisPicker_Previews: PreviewProvider {
    static var previews: some View {
        AxisPicker(initialAxis: "Hello", axisNames: ["Hello", "Goodbye"]) { axis in
            print("Value picked! Value: \(axis)")
        }
    }
}
