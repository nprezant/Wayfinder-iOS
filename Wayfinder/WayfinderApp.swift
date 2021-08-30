// Wayfinder

import SwiftUI

@main
struct WayfinderApp: App {
    @ObservedObject private var data = DbData()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    data.loadReflections()
                }
        }
    }
}
