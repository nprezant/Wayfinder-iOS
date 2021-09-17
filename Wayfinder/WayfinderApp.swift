// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    
    @StateObject private var dataStore = DataStore()
    @State private var selectedItem = 0
    @State private var lastSelectedItem = 0
    @State private var isPresented = false
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedItem) {
                ListView(dataStore: dataStore)
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Reflections")
                    }
                    .tag(0)
                Text("")
                    .tabItem {
                        Image(systemName: "plus.circle")
                        Text("New")
                    }
                    .font(.title)
                    .tag(1)
                ReportView(dataStore: dataStore)
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Reports")
                    }
                    .tag(2)
            }
            .onAppear {
                dataStore.loadReflections()
            }
            .onChange(of: selectedItem) {
                if selectedItem == 1 {
                    self.isPresented = true
                } else {
                    self.lastSelectedItem = $0
                }
            }
            .sheet(isPresented: $isPresented, onDismiss: {self.selectedItem = lastSelectedItem}) {
                EditViewSheet(
                    dataStore: dataStore,
                    isPresented: $isPresented,
                    dismissAction: {
                        self.selectedItem = lastSelectedItem
                    },
                    addAction: {
                        self.selectedItem = lastSelectedItem
                    }
                )
            }
        }
    }
}
