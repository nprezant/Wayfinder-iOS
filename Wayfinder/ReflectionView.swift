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

struct ReflectionView: View {
    @State private var activityName = ""
    @State private var isFlowState = false
    @State private var engagementValue = 50.0
    @State private var energyValue = 0.0

    @State private var isConfirmingCancel = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack {
                TextField("Activity name", text: $activityName)
                    .font(.system(size: 26))
                Spacer()
            }
            Toggle("Flow state", isOn: $isFlowState)
                .padding(.trailing, 5)
                .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
            ReflectionSlider(label: "Engagement", binding: $engagementValue, range: 0...100)
            ReflectionSlider(label: "Energy", binding: $energyValue, range: -100...100)
            Spacer()
        }
        .padding(.horizontal)
        .navigationBarItems(
            leading:
                Button("Cancel") {
                   isConfirmingCancel = true
                }
                .actionSheet(isPresented: $isConfirmingCancel, content: {
                    ActionSheet(title: Text("Are you sure you want to discard your changes?"),
                                buttons: [
                                    .cancel(Text("Keep Editing")),
                                    .destructive(Text("Discard Changes"), action: { self.presentationMode.wrappedValue.dismiss() })
                                ]
                    )
                }),
            trailing:
                Button("Done") {
                    self.presentationMode.wrappedValue.dismiss()
                }
        )
        .navigationBarBackButtonHidden(true)
    }
}

struct ReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionView()
    }
}
