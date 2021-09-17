// Wayfinder

import SwiftUI

struct ActivityReportView: View {
    @ObservedObject var dataStore: DataStore
    
    @State private var selectedActivity: String = ""
    @State private var averagedResult: Reflection.Averaged? = nil
    @State private var isPresented: Bool = false
    
    private func updateAverages() {
        dataStore.makeAverageReport(forName: selectedActivity) { results in
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
                Text("Activity Averages")
                    .font(.title)
                Spacer()
            }
            HStack {
                Button(action: {
                    isPresented = true
                }) {
                    // TODO if view is dismissed via swiping with an invalid selection
                    // nothing stops it from passing through
                    NameFieldView(name: selectedActivity)
                        .onChange(of: selectedActivity, perform: {_ in updateAverages()})
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
            NameView(name: $selectedActivity, nameOptions: dataStore.uniqueReflectionNames, canCreate: false)
        }
    }
}


struct ActivityReportView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityReportView(dataStore: DataStore.createExample())
    }
}
