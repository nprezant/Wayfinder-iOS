// Wayfinder

import SwiftUI

struct ReportView: View {
    @ObservedObject var dbData: DbData
    var body: some View {
        VStack {
            Text("Under construction")
        }
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(dbData: DbData())
    }
}
