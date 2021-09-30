// Wayfinder

import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case activity
    case tag

    var id: String { self.rawValue }
    
    var choicePrompt: String {
        switch self {
        case .activity:
            return "Choose Activity"
        case .tag:
            return "Choose Tag"
        }
    }
    
    var pluralized: String {
        switch self {
        case .activity:
            return "activities"
        case .tag:
            return "tags"
        }
    }
    
    func makeInclusionComparator(_ value: String) -> ((Reflection) -> Bool) {
        switch self {
        case .activity:
            return {$0.name == value}
        case .tag:
            return {$0.tags.contains(value)}
        }
    }
}

struct CategoryReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedCategory: Category = .activity
    @State private var selectedCategoryValue: String = ""
    @State private var averagedResult: Reflection.Averaged? = nil
    @State private var isPresented: Bool = false
    
    private func updateAverages() {
        func processResult(results: Result<Reflection.Averaged?, Error>) {
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                
            case .success(let averagedResult):
                self.averagedResult = averagedResult
            }
            
        }
        
        let inclusionComparator = selectedCategory.makeInclusionComparator(selectedCategoryValue)
        dataStore.makeAverageReport(inclusionComparator, completion: processResult)
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("\(selectedCategory.rawValue.capitalized)", selection: $selectedCategory) {
                    ForEach(Category.allCases) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
                .onChange(of: selectedCategory, perform: {_ in updateAverages()})
                .pickerStyle(MenuPickerStyle())
                .font(.title)
                Text("Average")
                    .font(.title)
                Spacer()
            }
            .padding([.top])
            HStack {
                Button(action: {
                    isPresented = true
                }) {
                    NamePickerField(name: selectedCategoryValue, prompt: selectedCategory.choicePrompt, font: .title2)
                        .onChange(of: selectedCategoryValue, perform: {_ in updateAverages()})
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).foregroundColor(Color.secondary.opacity(0.15)))
                }
                Spacer()
            }
            ReportListView(averagedResult: averagedResult)
            Spacer()
        }
        .padding()
        .onAppear(perform: updateAverages)
        .sheet(isPresented: $isPresented, onDismiss: updateAverages) {
            switch selectedCategory {
            case .activity:
                NamePicker($selectedCategoryValue, nameOptions: dataStore.uniqueReflectionNames, prompt: "Choose Activity", canCreate: false, parentIsPresenting: $isPresented)
            case .tag:
                NamePicker($selectedCategoryValue, nameOptions: dataStore.uniqueTagNames, prompt: "Choose Tag", canCreate: false, parentIsPresenting: $isPresented)
            }
        }
    }
}


struct CategoryReportView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryReportView(dataStore: DataStore.createExample())
    }
}
