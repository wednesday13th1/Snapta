import SwiftUI

private struct SelectedPhoto: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            SnaptaTheme.paper
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "photo").font(.system(size: 36)).foregroundStyle(SnaptaTheme.indigo.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity).clipped()
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(SnaptaTheme.line))
        .accessibilityLabel("選んだ写真")
    }
}

struct SavedScreen: View {
    @ObservedObject var flow: LearningFlow
    @State private var appeared = false

    var body: some View {
        Spacer()
        PaperPanel {
            VStack(spacing: 22) {
                SelectedPhoto(image: flow.capturedImage).frame(height: 190)
                ZStack {
                    Circle().fill(SnaptaTheme.moss.opacity(0.14)).frame(width: 70, height: 70)
                    Image(systemName: "checkmark").font(.system(size: 28, weight: .medium)).foregroundStyle(SnaptaTheme.moss)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                Text("写真の札ができました")
                    .font(SnaptaTheme.mincho(22, weight: .semibold))
                Text("この写真を使って、ことばかるたで遊ぼう。")
                    .font(.system(size: 15)).multilineTextAlignment(.center)
                    .foregroundStyle(SnaptaTheme.ink.opacity(0.64))
                PrimaryButton("ことばかるたで遊ぶ", icon: "rectangle.stack.fill") { flow.go(.quiz) }
            }
        }
        .padding(.horizontal, 20)
        Spacer().frame(height: 30)
        .onAppear { withAnimation(.easeOut(duration: 0.35)) { appeared = true } }
    }
}

struct QuizScreen: View {
    @ObservedObject var flow: LearningFlow
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            PaperPanel {
                VStack(spacing: 18) {
                    VStack(spacing: 5) {
                        Text("ことばかるた").font(.system(size: 12, weight: .bold)).tracking(2).foregroundStyle(SnaptaTheme.vermilion)
                        Text("このことばの写真はどれ？").font(SnaptaTheme.mincho(24, weight: .semibold))
                    }
                    WordCard(word: flow.word, reading: flow.currentEntry.reading, compact: true)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(flow.entries) { entry in
                            QuizPhotoCard(
                                entry: entry,
                                selected: flow.selectedAnswer == entry.id
                            )
                            .onTapGesture {
                                guard !flow.quizCompleted else { return }
                                withAnimation(.easeOut(duration: 0.2)) { flow.answer(entry) }
                            }
                        }
                    }

                    if let message = flow.quizMessage {
                        Text(message)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(flow.quizCompleted ? SnaptaTheme.vermilion : SnaptaTheme.indigo)
                            .multilineTextAlignment(.center).padding(.vertical, 4)
                    } else {
                        Text("ことばに合う写真の札をタップしよう")
                            .font(.system(size: 13)).foregroundStyle(SnaptaTheme.ink.opacity(0.5))
                    }

                    if flow.quizCompleted {
                        PrimaryButton("もう一度あそぶ", icon: "arrow.counterclockwise") {
                            withAnimation {
                                flow.selectedAnswer = nil
                                flow.quizMessage = nil
                                flow.quizCompleted = false
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
    }
}

private struct QuizPhotoCard: View {
    let entry: KarutaEntry
    let selected: Bool

    private var colors: [Color] {
        let palettes: [[Color]] = [
            [Color(red: 0.47, green: 0.65, blue: 0.70), SnaptaTheme.indigo],
            [Color(red: 0.62, green: 0.68, blue: 0.44), SnaptaTheme.moss],
            [Color(red: 0.78, green: 0.43, blue: 0.37), SnaptaTheme.vermilion],
            [Color(red: 0.65, green: 0.57, blue: 0.72), SnaptaTheme.indigo]
        ]
        return palettes[abs(entry.word.hashValue) % palettes.count]
    }

    var body: some View {
        ZStack {
            SnaptaTheme.paperLight
            GeometryReader { proxy in
                ZStack {
                    if let image = entry.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                    } else {
                        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: entry.symbol)
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .padding(5)
        }
        // Traditional karuta cards are noticeably taller than photo tiles.
        .aspectRatio(0.70, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(SnaptaTheme.indigo, lineWidth: selected ? 4 : 2.5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(SnaptaTheme.indigo.opacity(0.32), lineWidth: 1)
                .padding(5)
        }
        .background(SnaptaTheme.paperLight)
        .shadow(color: SnaptaTheme.ink.opacity(0.09), radius: 3, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityElement(children: .ignore).accessibilityLabel("画像の札").accessibilityAddTraits(.isButton)
    }
}
