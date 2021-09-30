// Wayfinder

import SwiftUI

struct NamePickerField: View {
    let name: String
    let prompt: String
    var font: Font = .body
    
    var body: some View {
        HStack {
            if name.isEmpty {
                Text("\(prompt)")
                    .foregroundColor(.secondary)
                    .font(font)
            } else {
                Text(name)
                    .font(font)
            }
            Spacer()
        }
    }
}

struct NamePickerField_Previews: PreviewProvider {
    static var previews: some View {
        NamePickerField(name: "", prompt: "Choose Activity", font: .title2)
            .previewLayout(.fixed(width: 300, height: 60))
        NamePickerField(name: "Stata PYD/YAS", prompt: "Add Tag")
            .previewLayout(.fixed(width: 300, height: 60))
    }
}
