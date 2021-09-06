// Wayfinder

import SwiftUI

struct NameView: View {
    @Binding var name: String
    @State var originalName: String
    let nameOptions: [String]
    
    @Environment(\.presentationMode) var presentationMode
    
    init(name: Binding<String>, nameOptions: [String]) {
        self._name = name
        self._originalName = State(initialValue: name.wrappedValue)
        self.nameOptions = nameOptions
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
                    }) {
                        Text(nameOption)
                    }
                }
                if filteredNames.isEmpty {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Create \"\(name)\"")
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Choose activity")
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
            NameView(name: .constant("dashboard"), nameOptions: names)
        }
        NavigationView {
            NameView(name: .constant("My new name"), nameOptions: names)
        }
    }
}
