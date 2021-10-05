// Wayfinder

import SwiftUI

enum Report: Int, CaseIterable, Identifiable {
    case bestOfAll
    case bestOf
    case categorical
    case weekly
    case daily
    case average
    
    var id: Int { self.rawValue }
    
    static var addableReports: [Report]{
        get {
            return [.bestOfAll, .bestOf, .average]
        }
    }
    
    var stringValue: String {
        get {
            switch self {
            case .bestOfAll:
                return "Best of All"
            case .bestOf:
                return "Best of"
            case .categorical:
                return "Category Average"
            case .weekly:
                return "Weekly Average"
            case .daily:
                return "Daily Average"
            case .average:
                return "Average"
            }
        }
    }
    
    func buildView(dataStore: DataStore) -> AnyView {
        switch self {
        case .bestOfAll:
            return AnyView(BestOfAllReportView(dataStore: dataStore))
        case .bestOf:
            return AnyView(BestOfReportView(dataStore: dataStore))
        case .categorical:
            return AnyView(CategoryReportView(dataStore: dataStore))
        case .weekly:
            return AnyView(WeeklyReportView(dataStore: dataStore))
        case .daily:
            return AnyView(DailyReportView(dataStore: dataStore))
        case .average:
            return AnyView(AveragedReportView(dataStore: dataStore))
        }
    }
}

struct ReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedIndex: Int = 0
    @State private var reports: [Report] = [.bestOfAll, .average]
    @State private var addNewPageIsPresented: Bool = false
    
    var body: some View {
        VStack {
            if !reports.isEmpty {
                TabView(selection: $selectedIndex) {
                    ForEach(reports.indices, id: \.self) { index in
                        reports[index].buildView(dataStore: dataStore)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
            } else {
                Spacer()
                Button { addNewPageIsPresented = true } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create a New Report!")
                    }
                }
                .padding()
                Spacer()
            }
            HStack {
                Button { removeCurrentPage() } label: { Image(systemName: "trash") }
                Spacer()
                Button { addNewPageIsPresented = true } label: { Image(systemName: "plus") }
            }
            .padding([.leading, .trailing, .bottom])
        }
        .actionSheet(isPresented: $addNewPageIsPresented) {
            var buttons: [ActionSheet.Button] = []
            for report in Report.addableReports {
                buttons.append(
                    .default(Text(report.stringValue.capitalized)) {
                        let insertionIndex = reports.isEmpty || selectedIndex == reports.count ? reports.endIndex : selectedIndex + 1
                        withAnimation {
                            reports.insert(report, at: insertionIndex)
                            selectedIndex = insertionIndex
                        }
                    }
                )
            }
            buttons.append(.cancel())
            
            return ActionSheet(title: Text("Choose Report to View"), buttons: buttons)
        }
    }
    
    func removeCurrentPage() {
        let indexToRemove = IndexSet(integer: selectedIndex)
        withAnimation {
            reports.remove(atOffsets: indexToRemove)
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        }
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(dataStore: DataStore())
    }
}
