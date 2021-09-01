// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    @StateObject private var dbData = DbData()
    var body: some Scene {
        WindowGroup {
            TabView() {
                HomeView(dbData: dbData)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                ListView(dbData: dbData)
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("History")
                    }
            }
            .onAppear {
                dbData.loadReflections()
            }
        }
    }
}
