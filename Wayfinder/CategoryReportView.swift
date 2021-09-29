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
        
        switch selectedCategory {
        case .activity:
            dataStore.makeAverageReport(forName: selectedCategoryValue, completion: processResult)
        case .tag:
            dataStore.makeAverageReport(forTag: selectedCategoryValue, completion: processResult)
        }
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
            HStack {
                Button(action: {
                    isPresented = true
                }) {
                    NameFieldView(name: selectedCategoryValue, prompt: selectedCategory.choicePrompt, font: .title2)
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
                NameView($selectedCategoryValue, nameOptions: dataStore.uniqueReflectionNames, prompt: "Choose Activity", canCreate: false)
            case .tag:
                NameView($selectedCategoryValue, nameOptions: dataStore.uniqueTagNames, prompt: "Choose Tag", canCreate: false)
            }
        }
    }
}


struct CategoryReportView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryReportView(dataStore: DataStore.createExample())
    }
}
