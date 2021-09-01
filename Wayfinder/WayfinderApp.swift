// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    @StateObject private var dbData = DbData()
    var body: some Scene {
        WindowGroup {
            TabView() {
                HomeView(dbData: dbData)
                    .tabItem { Image(systemName: "house.fill") }
                ListView(dbData: dbData)
                    .tabItem { Image(systemName: "list.bullet") }
            }
            .onAppear {
                dbData.loadReflections()
            }
        }
    }
}
