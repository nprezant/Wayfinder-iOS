// Wayfinder

import SwiftUI

struct NameFieldView: View {
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

struct NameFieldView_Previews: PreviewProvider {
    static var previews: some View {
        NameFieldView(name: "", prompt: "Choose Activity", font: .title2)
            .previewLayout(.fixed(width: 300, height: 60))
        NameFieldView(name: "Stata PYD/YAS", prompt: "Add Tag")
            .previewLayout(.fixed(width: 300, height: 60))
    }
}
