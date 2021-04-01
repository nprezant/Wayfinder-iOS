// Wayfinder

import SwiftUI

enum ReflectionResponseCategory {
    case Health
    case Life
    case Play
    case Love
    case None
}

struct ResponseItem: Identifiable {
    var id = UUID()
    var question: String
    var response: String = ""
    var category: ReflectionResponseCategory = .None
    
    var color: Color {
        switch category {
        case .Health:
            return .red
        case .Life:
            return .yellow
        case .Love:
            return .blue
        case .Play:
            return .green
        case .None:
            return .white
        }
    }
}

final class Question1Responses: ObservableObject {
    @Published var responses: [ResponseItem] = [
        ResponseItem(question: "First question", response: "Run through the park\nSo I was on a run the other day. I'm not really sure how long I need it to be to make it wrap", category: .Health),
        ResponseItem(question: "First question", response: "I certainly like playing, that's a thing I know. this is my second response", category: .Play)
    ]
}

extension Sequence {
    func indexed() -> Array<(offset: Int, element: Element)> {
        return Array(enumerated())
    }
}

struct LifeReflectionView: View {
    
    @State var fullScreenItem = ResponseItem(question: "")
    @State private var isFullScreen = false
    
    @State var questions = [
        "This is the first question",
        "And the second question",
        "And the third question",
    ]
    
    @ObservedObject var question1Responses: Question1Responses = Question1Responses()
    
    var body: some View {
        ScrollView{
            HStack {
                Text("First question")
                    .font(.title)
                Spacer()
            }.padding(.horizontal)
            ForEach(question1Responses.responses.indexed(), id: \.1.id){index, response in
                HStack {
                    Rectangle()
                        .fill(response.color)
                        .frame(maxWidth: 10)
                    VStack {
                        
                        let lines = response.response.components(separatedBy: .newlines)

                        let firstLine: String = lines.first ?? "Response"
                        let secondLine: String = lines.count > 1 ? lines[1] : ""
                        
                        HStack {
                            Text(firstLine)
                                .lineLimit(1)
                                .font(.system(size: 18, weight: .heavy, design: .default))
                            Spacer()
                        }
                        if (secondLine != "") {
                            HStack {
                                Text(secondLine)
                                    .lineLimit(1)
                                    .font(.system(size: 14, design: .default))
                                Spacer()
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .padding(.all)
                .background(Color.white)
                .cornerRadius(15)
                .clipped()
                .shadow(color: .init(red: 0.1, green: 0.1, blue: 0.1), radius: 11 , x: 0, y: 4)
                .padding(.horizontal)
                .padding(.vertical, 5)
                .onTapGesture {
                    fullScreenItem = response
                    isFullScreen.toggle()
                }
            }
            HStack {
                Spacer()
                Button(action: {
                        fullScreenItem = ResponseItem(question: questions[0])
                        isFullScreen.toggle()
                }) {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                }.padding(.trailing).frame(width: 50, height: 50)
            }
            HStack {
                Text("Second question")
                    .font(.title)
                Spacer()
            }.padding(.horizontal)
            HStack {
                Spacer()
                Button(action: {
                    fullScreenItem = ResponseItem(question: questions[1])
                    isFullScreen.toggle()
            }) {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                }.padding(.trailing).frame(width: 50, height: 50)
            }
        }.fullScreenCover(isPresented: $isFullScreen) {
            FullScreenView(isFullScreen: $isFullScreen, responseItem: $fullScreenItem)
        }
    }
}

private struct FullScreenView: View {
    @Binding var isFullScreen: Bool
    @Binding var responseItem: ResponseItem
    
    @State private var responseText: String
    
    init(isFullScreen: Binding<Bool>, responseItem: Binding<ResponseItem>) {
        self._isFullScreen = isFullScreen
        self._responseItem = responseItem
        self._responseText = .init(initialValue: responseItem.response.wrappedValue)
    }

    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(responseItem.question)
                        .font(.title)
                    Spacer()
                }
                Rectangle()
                    .fill(responseItem.color)
                    .frame(height: 4)
                MultilineTextField("Response...", text: $responseText)
                ChipList(viewModel: ChipViewModel())
                Text("done")
                    .onTapGesture {
                        responseItem.response = responseText
                        self.isFullScreen.toggle()
                    }
            }.padding()
        }
    }
}

struct LifeReflectionView_Previews: PreviewProvider {
    static var previews: some View {
        LifeReflectionView()
    }
}
