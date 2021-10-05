// Wayfinder

import SwiftUI

struct ErrorMessage: Identifiable {
    var id: String { title + message }
    let title: String
    let message: String
    
    func toAlert() -> Alert {
        return Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("Okay")))
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

var MonthShortNames: [Int: String] = [
    1: "Jan",
    2: "Feb",
    3: "Mar",
    4: "Apr",
    5: "May",
    6: "Jun",
    7: "Jul",
    8: "Aug",
    9: "Sep",
    10: "Oct",
    11: "Nov",
    12: "Dec"
]
