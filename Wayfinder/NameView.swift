// Wayfinder

import SwiftUI

struct NamePickerStyle {
    let nameSpecifier: String
    let cardFont: Font
    
    static var Activity: NamePickerStyle {
        get {
            return NamePickerStyle(nameSpecifier: "Choose Activity", cardFont: .title2)
        }
    }
    
    static var Tag: NamePickerStyle {
        get {
            return NamePickerStyle(nameSpecifier: "Add Tag", cardFont: .body)
        }
    }
}

struct NameView: View {
    @Binding var name: String
    @State var originalName: String
    let nameOptions: [String]
    let style: NamePickerStyle
    let canCreate: Bool
    let completion: ()->Void
    
    @Environment(\.presentationMode) var presentationMode
    
    init(_ name: Binding<String>, nameOptions: [String], nameType: NamePickerStyle, canCreate: Bool = true, completion: @escaping ()->Void = {}) {
        self._name = name
        self._originalName = State(initialValue: name.wrappedValue)
        self.nameOptions = nameOptions
        self.style = nameType
        self.canCreate = canCreate
        self.completion = completion
    }
    
    var body: some View {
        VStack {
            SearchBar(text: $name)
            List {
                let filteredNames =
                    nameOptions.filter {
                        name.isEmpty
                            ? true
                            : $0.lowercased().contains(self.name.lowercased()) }
                ForEach(filteredNames, id: \.self) { nameOption in
                    Button(action: {
                        name = nameOption
                        self.presentationMode.wrappedValue.dismiss()
                        completion()
                    }) {
                        Text(nameOption)
                    }
                }
                if filteredNames.isEmpty {
                    if canCreate {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                            completion()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create \"\(name)\"")
                            }
                            .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("No matches found")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("\(style.nameSpecifier)")
        .navigationBarItems(
            leading: Button(action: {
                name = originalName
                self.presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                    Text("Cancel")
                        .font(.title3)
                }
            }
        )
    }
}

struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        let names = ["Stata PYD/YAS", "Florida dashboard", "Florida YAS dashboard", "Fred", "PYD/YAS", "Florida"]
        NavigationView {
            NameView(.constant("dashboard"), nameOptions: names, nameType: .Activity)
        }
        NavigationView {
            NameView(.constant("My new name"), nameOptions: names, nameType: .Tag)
        }
    }
}
