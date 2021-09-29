// Wayfinder

import SwiftUI

struct ReportView: View {
    @ObservedObject var dataStore: DataStore
    var body: some View {
        TabView {
            DailyReportView(dataStore: dataStore)
            WeeklyReportView(dataStore: dataStore)
            ActivityReportView(dataStore: dataStore)
            TagReportView(dataStore: dataStore)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(dataStore: DataStore())
    }
}
