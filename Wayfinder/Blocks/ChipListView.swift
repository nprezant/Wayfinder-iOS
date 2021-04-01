// Wayfinder

import SwiftUI

struct ChipsDataModel: Identifiable {
    let id = UUID()
    @State var isSelected: Bool
    let systemImage: String
    let title: LocalizedStringKey
    let color: Color
}

class ChipsViewModel: ObservableObject {
    @Published var dataObject: [ChipsDataModel] = [
        ChipsDataModel(isSelected: false, systemImage: "pencil.circle", title: "Health", color: Color.red),
        ChipsDataModel(isSelected: false, systemImage: "pencil.circle", title: "Work", color: Color.blue),
        ChipsDataModel(isSelected: false, systemImage: "pencil.circle", title: "Play", color: Color.green),
        ChipsDataModel(isSelected: false, systemImage: "pencil.circle", title: "Love", color: Color.yellow),
    ]
}


struct Chip: View {
    let systemImage: String
    let titleKey: LocalizedStringKey
    @State var isSelected: Bool
    let color: Color
    var body: some View {
        let backgroundColor = color.opacity(isSelected ? 0.5 : 0.75)
        HStack {
//            Image.init(systemName: systemImage).font(.body)
            Text(titleKey).font(.body).lineLimit(1)
        }.padding(.all)
        .foregroundColor(isSelected ? .white : .black)
        .background(backgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(backgroundColor, lineWidth: 1.5)
        ).onTapGesture {
            isSelected.toggle()
        }
    }
}

struct ChipList: View {
    @ObservedObject var viewModel = ChipsViewModel()
    var body: some View {
        ScrollView(Axis.Set.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.dataObject) { chipData in
                    Chip(systemImage: chipData.systemImage,
                          titleKey: chipData.title,
                          isSelected: chipData.isSelected,
                          color: chipData.color
                    )
                }
            }
        }
    }
}

struct ChipListView_Previews: PreviewProvider {
    static var previews: some View {
        ChipList()
    }
}
