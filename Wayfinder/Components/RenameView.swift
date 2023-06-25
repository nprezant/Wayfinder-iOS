// Wayfinder

import SwiftUI

struct RenameView: View {
    @Binding var isPresented: Bool
    var oldName: String
    var invalidNames: [String]
    var saveAction: ((String)->Void)
    
    @State var newName: String = ""
    
    private enum Field: Int, Hashable {
        case name
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack {
            HStack { Text("Rename View"); Spacer() }.font(.title).padding()
            HStack { Text("Old Name:"); Text("\(oldName)").underline(); Spacer() }.padding()
            if #available(iOS 15.0, *) {
                TextField("Type new name here...", text: $newName)
                    .focused($focusedField, equals: .name)
                    .padding()
            } else {
                TextField("Type new name here...", text: $newName)
                    .padding()
            }
            let nameIsInvalid = invalidNames.contains(newName)
            if nameIsInvalid {
                Text("A '\(newName)' view already exists")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            Button {
               saveAction(newName)
               isPresented = false
            } label: {
                Text("Rename")
                    .disabled(nameIsInvalid || newName.isEmpty)
            }.padding()
            Spacer()
        }
        .padding()
    }
}

struct RenameView_Previews: PreviewProvider {
    static var previews: some View {
        RenameView(isPresented: .constant(true), oldName: "Work", invalidNames: [], saveAction: {_ in})
    }
}









struct CustomTextField: UIViewRepresentable {

    class Coordinator: NSObject, UITextFieldDelegate {

        @Binding var text: String
        var didBecomeFirstResponder = false

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

    }

    @Binding var text: String
    var isFirstResponder: Bool = false

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        return textField
    }

    func makeCoordinator() -> CustomTextField.Coordinator {
        return Coordinator(text: $text)
    }

    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        uiView.text = text
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
    }
}

