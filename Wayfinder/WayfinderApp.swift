// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    
    @StateObject private var store = Store()
    @State private var selectedItem = 0
    @State private var lastSelectedItem = 0
    @State private var isPresented = false
    @State private var errorMessage: ErrorMessage?
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedItem) {
                ListView(store: store)
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
                ReportView(store: store)
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Reports")
                    }
                    .tag(2)
            }
            .onAppear {
                store.syncInitial()
            }
            .onChange(of: selectedItem) {
                if selectedItem == 1 {
                    self.isPresented = true
                } else {
                    self.lastSelectedItem = $0
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { output in
                // App may be about to be terminated
                store.savePreferences()
             })
            .sheet(isPresented: $isPresented, onDismiss: {self.selectedItem = lastSelectedItem}) {
                EditViewSheet(
                    store: store,
                    isPresented: $isPresented,
                    errorMessage: $errorMessage,
                    dismissAction: {
                        self.selectedItem = lastSelectedItem
                    },
                    addAction: {
                        self.selectedItem = lastSelectedItem
                    }
                )
            }
            .alert(item: $errorMessage) { msg in
                msg.toAlert()
            }
        }
    }
}
