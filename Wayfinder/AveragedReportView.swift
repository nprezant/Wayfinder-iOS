// Wayfinder

import SwiftUI

enum AverageOption : String, CaseIterable, Identifiable {
    case activity
    case tag
    case daily
    case weekly

    var id: String { self.rawValue }
    
    func buildView(dataStore: DataStore) -> AnyView {
        switch self {
        case .activity:
            return AnyView(CategoryReportView(dataStore: dataStore, showHeader: false, selectedCategory: .activity))
        case .tag:
            return AnyView(CategoryReportView(dataStore: dataStore, showHeader: false, selectedCategory: .tag))
        case .daily:
            return AnyView(DailyReportView(dataStore: dataStore, showHeader: false))
        case .weekly:
            return AnyView(WeeklyReportView(dataStore: dataStore, showHeader: false))
        }
    }
}

struct AveragedReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedAverageOption: AverageOption = .activity
    
    var body: some View {
        VStack {
            HStack {
                Picker("\(selectedAverageOption.rawValue.capitalized)", selection: $selectedAverageOption) {
                    ForEach(AverageOption.allCases) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .font(.title)
                Text("Average")
                    .font(.title)
                Spacer()
            }
            .padding([.top])
            .padding([.top, .leading, .trailing])
            selectedAverageOption.buildView(dataStore: dataStore)
                .id(selectedAverageOption) // Without this view won't update when changing between tag/activity
        }
    }
}

struct AveragedReportView_Previews: PreviewProvider {
    static var previews: some View {
        AveragedReportView(dataStore: DataStore.createExample())
    }
}
