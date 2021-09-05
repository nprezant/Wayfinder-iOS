// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    
    @StateObject private var dbData = DbData()
    @State private var selectedItem = 0
    @State private var lastSelectedItem = 0
    @State private var isPresented = false
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedItem) {
                ListView(dbData: dbData)
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
                ReportView(dbData: dbData)
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Reports")
                    }
                    .tag(2)
            }
            .onAppear {
                dbData.loadReflections()
            }
            .onChange(of: selectedItem) {
                if selectedItem == 1 {
                    self.isPresented = true
                } else {
                    self.lastSelectedItem = $0
                }
            }
            .sheet(isPresented: $isPresented) {
                EditViewSheet(
                    dbData: dbData,
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
