// Wayfinder

import SwiftUI

struct ReflectionSlider: View {
    let label: String
    let binding: Binding<Double>
    var range: ClosedRange<Double> = 1...100
    @State private var description = ""
    @State private var isShowingDescription = false

    var body: some View {
        Group {
            HStack {
                Text(label)
                Spacer()
            }
            .contentShape(Rectangle()) // Makes entire HStack tappable
            .onTapGesture {
                withAnimation {
                    self.isShowingDescription.toggle()
                }
            }
            Slider(
                value: binding,
                in: range,
                step: 1
            )
            if isShowingDescription {
                MultilineTextField("\(label) notes...", text: $description)
            }
        }
    }
}

struct CheckinReflectionView: View {
    @State private var healthValue = 50.0
    @State private var workValue = 50.0
    @State private var playValue = 50.0
    @State private var loveValue = 50.0

    @State private var isEditing = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            ReflectionSlider(label: "Health", binding: $healthValue)
            ReflectionSlider(label: "Work", binding: $workValue)
            ReflectionSlider(label: "Play", binding: $playValue)
            ReflectionSlider(label: "Love", binding: $loveValue)
        }
        .padding(.horizontal)
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
            ReflectionSlider(label: "Engagement", binding: $engagementValue)
            ReflectionSlider(label: "Energy", binding: $energyValue, range: -100...100)
        }
        .padding(.horizontal)
    }
}

struct NoteReflectionView: View {
    @State private var text = ""
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            MultilineTextField("Record a note here...", text: $text)
        }
    }
}

struct ReflectionChooserView: View {
    var body: some View {
        VStack {
            link(label: "How's it going?", destination: CheckinReflectionView())
            link(label: "Work", destination: WorkReflectionView())
            link(label: "Life", destination: LifeReflectionView())
            link(label: "Note", destination: NoteReflectionView())
        }
        .padding(.horizontal, 36)
    }

    private func link<Destination: View>(label: String, destination: Destination) -> some View {
        return NavigationLink(destination: destination) {
            Text(label)
                .frame(minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .none)
                .font(.system(size: 20))
                .padding(EdgeInsets(
                            top: 5, leading: 10,
                            bottom: 5, trailing: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 2.0))
        }
    }
}



struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                NavigationLink(destination: ReflectionChooserView()) {
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
