// Wayfinder

import SwiftUI

enum AverageOption : String, CaseIterable, Identifiable {
    case activity
    case tag
    case daily
    case weekly

    var id: String { self.rawValue }
    
    func buildView(store: Store) -> AnyView {
        switch self {
        case .activity:
            return AnyView(CategoryReportView(store: store, showHeader: false, selectedCategory: .activity))
        case .tag:
            return AnyView(CategoryReportView(store: store, showHeader: false, selectedCategory: .tag))
        case .daily:
            return AnyView(DailyReportView(store: store, showHeader: false))
        case .weekly:
            return AnyView(WeeklyReportView(store: store, showHeader: false))
        }
    }
}

struct AveragedReportView: View {
    @ObservedObject var store: Store
    
    @State private var selectedAverageOption: AverageOption = .activity
    
    var body: some View {
        VStack {
            HStack {
                Text(store.activeAxis)
                Menu(content: {
                    Picker(selection: $selectedAverageOption, label: Text(selectedAverageOption.rawValue.capitalized)) {
                        ForEach(AverageOption.allCases) { option in
                            Text(option.rawValue.capitalized).tag(option)
                        }
                    }
                }, label: {
                    Text(selectedAverageOption.rawValue.capitalized)
                })
                Text("Average")
                Spacer()
            }
            .font(.title)
            .padding([.top])
            .padding([.top, .leading, .trailing])
            selectedAverageOption.buildView(store: store)
                .id(selectedAverageOption) // Without this view won't update when changing between tag/activity
        }
    }
}

struct AveragedReportView_Previews: PreviewProvider {
    static var previews: some View {
        AveragedReportView(store: Store.createExample())
    }
}
