// Wayfinder

import SwiftUI

struct NamePicker: View {
    @Binding var name: String
    @State var originalName: String
    let nameOptions: [String]
    let prompt: String
    let canCreate: Bool
    let completion: ()->Void
    var parentIsPresenting: Binding<Bool>? = nil // If supplied (e.g. when using in a sheet) additional header text and buttons are displayed that are otherwise handled by the navigation view
    
    @Environment(\.presentationMode) var presentationMode
    
    init(_ name: Binding<String>, nameOptions: [String], prompt: String, canCreate: Bool = true, parentIsPresenting: Binding<Bool>? = nil, completion: @escaping ()->Void = {}) {
        self._name = name
        self._originalName = State(initialValue: name.wrappedValue)
        self.nameOptions = nameOptions
        self.prompt = prompt
        self.canCreate = canCreate
        self.parentIsPresenting = parentIsPresenting
        self.completion = completion
    }
    
    var body: some View {
        VStack {
            if parentIsPresenting != nil {
                HStack {
                    Button("Dismiss") {
                        name = originalName
                        parentIsPresenting?.wrappedValue = false
                    }
                    Spacer()
                }
                .padding(/*@START_MENU_TOKEN@*/[.top, .leading, .trailing]/*@END_MENU_TOKEN@*/)
                HStack {
                    Text(prompt)
                        .font(.title.bold())
                    Spacer()
                }
                .padding()
            }
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
        .navigationTitle(prompt)
        .navigationBarItems(
            leading: Button(action: {
                name = originalName
                self.presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.backward")
                        .font(.title2.bold())
                    Text("Cancel")
                        .font(.body)
                }
            }
        )
    }
}

struct NamePicker_Previews: PreviewProvider {
    static var previews: some View {
        let names = ["Stata PYD/YAS", "Florida dashboard", "Florida YAS dashboard", "Fred", "PYD/YAS", "Florida"]
        Group {
            NavigationView {
                NamePicker(.constant("dashboard"), nameOptions: names, prompt: "Choose Activity")
            }
            VStack {
                NamePicker(.constant("dashboard"), nameOptions: names, prompt: "Choose Activity", parentIsPresenting: .constant(true))
            }
        }
    }
}
