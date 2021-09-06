// Wayfinder

import SwiftUI

struct ReportView: View {
    @ObservedObject var dbData: DbData
    var body: some View {
        TabView {
            DailyReportView(dbData: dbData)
            WeeklyReportView(dbData: dbData)
            ActivityReportView(dbData: dbData)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(dbData: DbData())
    }
}
