// Wayfinder

import SwiftUI

struct ReportView: View {
    @ObservedObject var dataStore: DataStore
    var body: some View {
        TabView {
            DailyReportView(dataStore: dataStore)
            WeeklyReportView(dataStore: dataStore)
            CategoryReportView(dataStore: dataStore)
            BestOfReportView(dataStore: dataStore)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(dataStore: DataStore())
    }
}
