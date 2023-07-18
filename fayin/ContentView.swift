import SwiftUI
import AVFoundation

struct PhoneticCard: Decodable {
    var phonetic: String
    var examples: [String]
    var markedLetters: [String]
    var audioFilename: String
}

struct ContentView: View {
    @State var cards: [PhoneticCard] = loadCards(from: "Phonetic")
    @State private var removedCards = [PhoneticCard]()
    @State private var cardOffset: CGSize = .zero

    var body: some View {
        if cards.isEmpty {
            VStack {
                Text("恭喜您，成功完成了这次学习！！！")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                Button(action: {
                    self.cards = self.removedCards
                    self.removedCards.removeAll()
                }) {
                    Text("再来一次")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        } else {
            ZStack {
                ForEach(cards.indices, id: \.self) { index in
                    CardView(card: cards[index])
                        .offset(index == cards.count - 1 ? cardOffset : .zero)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    if index == cards.count - 1 {
                                        self.cardOffset = gesture.translation
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        if self.cardOffset.height < -200 && !cards.isEmpty {
                                            let removedCard = cards.removeLast()
                                            removedCards.append(removedCard)
                                        } else if self.cardOffset.height > 200 && !removedCards.isEmpty {
                                            let previousCard = removedCards.removeLast()
                                            cards.append(previousCard)
                                        }
                                        self.cardOffset = .zero
                                    }
                                }
                        )
                        .animation(.easeOut)
                }
            }
            .frame(height: 300)
        }
    }
}

struct CardView: View {
    @State var isFlipped: Bool = false
    var card: PhoneticCard
    @State var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray, radius: 5, x: 0, y: 5)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0.0, y: 1.0, z: 0.0))

            if isFlipped {
                ScrollView {
                    VStack {
                        ForEach(Array(zip(card.examples, card.markedLetters)), id: \.0) { example, markedLetter in
                            highlightedText(for: example, highlightedChar: markedLetter)
                                .font(.title)
                                .padding()
                        }
                    }
                }
                .padding()
            } else {
                VStack {
                    Text(card.phonetic)
                        .font(.system(size: 30, design: .monospaced)) // Use monospaced font for phonetic symbols
                        .padding()

                    Button(action: {
                        playSound(filename: card.audioFilename)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .frame(width: 350, height: 250)
        .onTapGesture {
            withAnimation(Animation.spring(response: 0.7, dampingFraction: 0.5, blendDuration: 0.5)) {
                self.isFlipped.toggle()
            }
        }
    }

    func highlightedText(for text: String, highlightedChar: String) -> some View {
        let components: [String] = text.components(separatedBy: highlightedChar)
        return components.enumerated().map { index, component in
            index < components.count - 1 ?
                Text(component).foregroundColor(.black) + Text(highlightedChar).foregroundColor(.red) :
                Text(component).foregroundColor(.black)
        }.reduce(Text(""), +)
    }

    func playSound(filename: String) {
        if let path = Bundle.main.path(forResource: filename, ofType: nil) {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                // Couldn't load file :(
            }
        }
    }
    
    
}

func loadCards(from filename: String) -> [PhoneticCard] {
    if let url = Bundle.main.url(forResource:filename, withExtension: "json"),
       let data = try? Data(contentsOf: url),
       let cards = try? JSONDecoder().decode([PhoneticCard].self, from: data) {
        return cards
    }
    return []
}

