// Wayfinder

import SwiftUI

struct ReflectionSlider: View {
    let label: String
    let binding: Binding<Double>
    var range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
            Spacer()
        }.contentShape(Rectangle()) // Makes entire HStack tappable
        Slider(
            value: binding,
            in: range,
            step: 1
        )
    }
}

struct WorkReflectionView: View {
    @State private var activityName = ""
    @State private var isFlowState = false
    @State private var engagementValue = 50.0
    @State private var energyValue = 0.0

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack {
                TextField("Activity name", text: $activityName)
                    .font(.system(size: 26))
                Spacer()
            }
            Toggle("Flow state", isOn: $isFlowState)
            ReflectionSlider(
                label: "Engagement", binding: $engagementValue, range: 0...100)
            ReflectionSlider(
                label: "Energy", binding: $energyValue, range: -100...100)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                NavigationLink(destination: WorkReflectionView()) {
                    Text("Reflect")
                        .font(.system(size: 40))
                        .padding(EdgeInsets(
                                    top: 10, leading: 20,
                                    bottom: 10, trailing: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 40.0)
                                .stroke(lineWidth: 2.0)
                    )
                }
                Spacer()
                Text("Summary info")
                Spacer()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
