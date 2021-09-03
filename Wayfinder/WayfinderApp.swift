// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    
    @StateObject private var dbData = DbData()
    @State private var selectedItem = 0
    @State private var lastSelectedItem = 0
    @State private var isPresented = false
    
    @State private var newReflectionData = Reflection.Data()
    func saveAction() -> Void {
        dbData.saveReflection(reflection: newReflectionData.reflection)
        newReflectionData = Reflection.Data()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedItem) {
                ListView(dbData: dbData)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Reflections")
                    }
                    .tag(0)
                Text("")
                    .tabItem {
                        Image(systemName: "plus.circle")
                        Text("Add")
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
                NavigationView {
                    EditView(data: $newReflectionData)
                        .navigationBarItems(
                            leading: Button("Dismiss") {
                                isPresented = false
                                self.selectedItem = lastSelectedItem
                            },
                            trailing: Button("Add") {
                                saveAction()
                                isPresented = false
                                self.selectedItem = lastSelectedItem
                            }
                        )
                }
            }
        }
    }
}
