// Wayfinder

import SwiftUI

struct TagReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedTag: String = ""
    @State private var averagedResult: Reflection.Averaged? = nil
    @State private var isPresented: Bool = false
    
    private func updateAverages() {
        dataStore.makeAverageReport(forTag: selectedTag) { results in
            switch results {
            case .failure(let error):
                print(error.localizedDescription)
                
            case .success(let averagedResult):
                self.averagedResult = averagedResult
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Tag Average")
                    .font(.title)
                Spacer()
            }
            HStack {
                Button(action: {
                    isPresented = true
                }) {
                    // TODO if view is dismissed via swiping with an invalid selection
                    // nothing stops it from passing through
                    NameFieldView(name: selectedTag, prompt: "Choose Tag", font: .title2)
                        .onChange(of: selectedTag, perform: {_ in updateAverages()})
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
            NameView($selectedTag, nameOptions: dataStore.uniqueTagNames, prompt: "Choose Tag", canCreate: false)
        }
    }
}


struct TagReportView_Previews: PreviewProvider {
    static var previews: some View {
        TagReportView(dataStore: DataStore.createExample())
    }
}
