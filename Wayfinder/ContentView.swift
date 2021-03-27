// Wayfinder

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
           HomeView()
             .tabItem {
                Image(systemName: "homepod")
                Text("Home")
           }
           HistoryView()
            .tabItem {
                Image(systemName: "pencil.tip")
                Text("History")
            }
           InsightsView()
             .tabItem {
                Image(systemName: "macmini")
                Text("Insights")
          }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
