// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    @State private var dbData = DbData()
    var body: some Scene {
        WindowGroup {
            TabView() {
                HomeView(dbData: $dbData)
                    .tabItem { Image(systemName: "house.fill") }
                ListView(reflections: $dbData.reflections)
                    .tabItem { Image(systemName: "list.bullet") }
            }
            .onAppear {
                dbData.loadReflections()
            }
        }
    }
}
