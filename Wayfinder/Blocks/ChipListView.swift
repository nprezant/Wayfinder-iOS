// Wayfinder

import SwiftUI

struct ChipData: Identifiable {
    let id = UUID()
    var isSelected: Bool
    let title: LocalizedStringKey
    let color: Color
}

class ChipViewModel: ObservableObject {
    @Published var dataObject: [ChipData] = [
        ChipData(isSelected: false, title: "Health", color: Color.red),
        ChipData(isSelected: false, title: "Work", color: Color.blue),
        ChipData(isSelected: false, title: "Play", color: Color.green),
        ChipData(isSelected: false, title: "Love", color: Color.yellow),
    ]

    func setSelected(id: UUID) -> Void {
        for (index, chipData) in dataObject.enumerated() {
            dataObject[index].isSelected = chipData.id == id
        }
    }
}


struct Chip: View {
    @Binding var chipData: ChipData

    var body: some View {
        let backgroundColor = chipData.color.opacity(chipData.isSelected ? 0.5 : 0.75)
        Text(chipData.title).font(.body).lineLimit(1)
            .padding(.all)
            .foregroundColor(chipData.isSelected ? .white : .black)
            .background(backgroundColor)
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(backgroundColor, lineWidth: 1.5)
            )
    }
}

struct ChipList: View {
    @ObservedObject var viewModel: ChipViewModel

    var body: some View {
        ScrollView(Axis.Set.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.dataObject.indexed(), id: \.1.id) { index, chipData in
                    Chip(chipData: self.$viewModel.dataObject[index])
                        .onTapGesture {
                            viewModel.setSelected(id: chipData.id)
                        }
                }
            }
        }
    }
}

struct ChipListView_Previews: PreviewProvider {
    static var previews: some View {
        ChipList(viewModel: ChipViewModel())
    }
}
