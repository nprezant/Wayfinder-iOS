// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    @State private var dbData = DbData()
    var body: some Scene {
        WindowGroup {
            HomeView(dbData: $dbData)
                .onAppear {
                    dbData.loadReflections()
                }
        }
    }
}
