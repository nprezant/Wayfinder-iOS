// Wayfinder

import SwiftUI

struct NameFieldView: View {
    let name: String
    
    var body: some View {
        HStack {
            if name.isEmpty {
                Text("Choose activity")
                    .foregroundColor(.secondary)
                    .font(.title2)
            } else {
                Text(name)
                    .font(.title2)
            }
            Spacer()
        }
    }
}

struct NameFieldView_Previews: PreviewProvider {
    static var previews: some View {
        NameFieldView(name: "")
            .previewLayout(.fixed(width: 300, height: 60))
        NameFieldView(name: "Stata PYD/YAS")
            .previewLayout(.fixed(width: 300, height: 60))
    }
}
