// Wayfinder

import SwiftUI

struct NameFieldView: View {
    let name: String
    let style: NamePickerStyle
    
    var body: some View {
        HStack {
            if name.isEmpty {
                Text("\(style.nameSpecifier)")
                    .foregroundColor(.secondary)
                    .font(style.cardFont)
            } else {
                Text(name)
                    .font(style.cardFont)
            }
            Spacer()
        }
    }
}

struct NameFieldView_Previews: PreviewProvider {
    static var previews: some View {
        NameFieldView(name: "", style: .Activity)
            .previewLayout(.fixed(width: 300, height: 60))
        NameFieldView(name: "Stata PYD/YAS", style: .Tag)
            .previewLayout(.fixed(width: 300, height: 60))
    }
}
