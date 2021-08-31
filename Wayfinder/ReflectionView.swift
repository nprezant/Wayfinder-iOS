// Wayfinder

import SwiftUI

struct ReflectionSlider: View {
    let label: String
    @Binding var value: Int64
    var range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
            Spacer()
        }.contentShape(Rectangle()) // Makes entire HStack tappable
        Slider(
            value: Binding<Double>(
                get: { return Double(value) },
                set: { value = Int64(truncating: $0 as NSNumber) }),
            in: range,
            step: 1
        )
    }
}

struct ReflectionView: View {
    @Binding var reflectionData: Reflection.Data
    @State private var isConfirmingCancel = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack {
                TextField("Activity name", text: $reflectionData.name)
                    .font(.system(size: 26))
                Spacer()
            }
            Toggle("Flow state", isOn: $reflectionData.isFlowState)
                .padding(.trailing, 5)
                .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
            ReflectionSlider(label: "Engagement", value: $reflectionData.engagement, range: 0...100)
            ReflectionSlider(label: "Energy", value: $reflectionData.energy, range: -100...100)
            Spacer()
        }
        .padding(.horizontal)
        /*.navigationBarItems(
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
        .navigationBarBackButtonHidden(true)*/
    }
}

struct ReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionView(reflectionData: .constant(Reflection.exampleData[0].data))
    }
}
